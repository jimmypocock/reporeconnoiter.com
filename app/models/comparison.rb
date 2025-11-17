class Comparison < ApplicationRecord
  #--------------------------------------
  # CONFIGURATION
  #--------------------------------------

  # Similarity threshold for fuzzy query matching (0.0 - 1.0)
  # Higher = stricter matching, fewer cache hits
  # Lower = looser matching, more cache hits (but potential false positives)
  # Default: 0.8 (high precision - catches exact matches + typos, ~99% accuracy)
  SIMILARITY_THRESHOLD = ENV.fetch("COMPARISON_SIMILARITY_THRESHOLD", "0.8").to_f

  # Cache TTL in days - comparisons older than this are considered stale
  # Default: 7 days (balances freshness with API cost savings)
  CACHE_TTL_DAYS = ENV.fetch("COMPARISON_CACHE_DAYS", "7").to_i

  # Conservative cost estimate for budget reservation
  # Varies by number of repos analyzed (typically 5-15 repos @ ~$0.01 each)
  # Set higher than average to avoid budget overruns
  ESTIMATED_COST = 0.15  # $0.15 per comparison (actual: $0.05-0.20)

  #--------------------------------------
  # ASSOCIATIONS
  #--------------------------------------

  belongs_to :user, optional: true
  has_many :comparison_categories, dependent: :restrict_with_error
  has_many :categories, through: :comparison_categories
  has_many :comparison_repositories, dependent: :restrict_with_error
  has_many :repositories, through: :comparison_repositories

  #--------------------------------------
  # VALIDATIONS
  #--------------------------------------

  validates :cost_usd, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :input_tokens, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true
  validates :normalized_query, presence: true
  validates :output_tokens, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true
  validates :user_query, presence: true, length: { minimum: 1, maximum: 500 }
  validates :view_count, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  validate :user_query_not_blank

  #--------------------------------------
  # CALLBACKS
  #--------------------------------------

  before_validation :normalize_query
  before_save :calculate_cost, if: -> { model_used.present? && input_tokens.present? && output_tokens.present? }

  #--------------------------------------
  # SCOPES
  #--------------------------------------

  scope :cached, -> { where("created_at > ?", CACHE_TTL_DAYS.days.ago) }
  scope :past_7_days, -> { where("created_at >= ?", 7.days.ago) }
  scope :past_30_days, -> { where("created_at >= ?", 30.days.ago) }
  scope :popular, -> { order(view_count: :desc) }
  scope :recent, -> { order(created_at: :desc) }

  # Comprehensive search across all relevant comparison fields and associated categories
  # Searches: user_query, technologies, problem_domains, architecture_patterns, and category names
  # Includes synonym expansion, fuzzy matching via pg_trgm, and relevance scoring
  # Delegates to ComparisonSearchQuery for complex SQL logic
  # Can be chained with other scopes (e.g., .cached.search)
  # @param search_term [String] The search term to match (case-insensitive)
  # @param fuzzy [Boolean] Use fuzzy word_similarity matching (default: true)
  scope :search, ->(search_term, fuzzy: true) {
    ComparisonSearchQuery.call(search_term:, fuzzy:, scope: all)
  }

  # Fuzzy match against normalized_query using PostgreSQL's pg_trgm SIMILARITY function
  # Returns records with similarity_score attribute ordered by best match first
  # Delegates to ComparisonSimilarityQuery for pg_trgm SQL logic
  # Can be chained with other scopes (e.g., .cached.with_similarity_to)
  # @param query [String] The query string to match against
  # @param threshold [Float] Minimum similarity score (0.0-1.0)
  scope :with_similarity_to, ->(query, threshold) {
    ComparisonSimilarityQuery.call(query:, threshold:, scope: all)
  }

  #--------------------------------------
  # PUBLIC INSTANCE METHODS
  #--------------------------------------

  def increment_view_count!
    increment!(:view_count)
  end

  def recommended_repository
    comparison_repositories.min_by(&:rank)&.repository
  end

  #--------------------------------------
  # CLASS METHODS
  #--------------------------------------

  class << self
    # Find similar cached comparison using fuzzy matching
    # Uses PostgreSQL's pg_trgm SIMILARITY() for fuzzy text matching
    # Returns: [comparison, similarity_score] or [nil, 0.0]
    def find_similar_cached(query)
      result = cached.with_similarity_to(query, SIMILARITY_THRESHOLD).first
      return [ nil, 0.0 ] unless result

      # similarity_score is available as an attribute added by with_similarity_to scope
      [ result, result.similarity_score ]
    end

    # Normalize query string for consistent matching
    # Replicates: .strip.downcase.squish
    def normalize_query_string(query)
      query.to_s.strip.downcase.squish
    end
  end

  private

  #--------------------------------------
  # PRIVATE METHODS
  #--------------------------------------

  def calculate_cost
    self.cost_usd = OpenAi.calculate_cost(
      input_tokens:,
      model: model_used,
      output_tokens:
    )
  end

  def normalize_query
    self.normalized_query = self.class.normalize_query_string(user_query)
  end

  def user_query_not_blank
    if user_query.present? && user_query.strip.blank?
      errors.add(:user_query, "cannot be only whitespace")
    end
  end
end
