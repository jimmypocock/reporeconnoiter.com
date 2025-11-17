class AnalysisDeep < Analysis
  #--------------------------------------
  # CONFIGURATION
  #--------------------------------------

  # Daily budget cap for deep analysis (expensive ~$0.05-0.10 per repo)
  # Default: $0.50/day (~5-10 deep analyses per day)
  DAILY_BUDGET = ENV.fetch("ANALYSIS_DEEP_DAILY_BUDGET", "0.50").to_f

  # Conservative cost estimate for budget reservation (actual cost varies)
  # Set higher than average to avoid budget overruns
  ESTIMATED_COST = 0.08  # $0.08 per analysis (actual: $0.05-0.10)

  # Rate limit per user per day
  # Default: 3 (prevents individual users from exhausting daily budget)
  RATE_LIMIT_PER_USER = ENV.fetch("ANALYSIS_DEEP_RATE_LIMIT_PER_USER", "3").to_i

  # Default expiration for deep analysis (longer cache since expensive)
  # Default: 30 days (deep analysis changes slowly, expensive to regenerate)
  DEFAULT_EXPIRATION_DAYS = ENV.fetch("ANALYSIS_DEEP_EXPIRATION_DAYS", "30").to_i

  #--------------------------------------
  # DEEP ANALYSIS FIELDS
  #--------------------------------------
  # - readme_analysis: Comprehensive README review, docs quality, examples, getting started
  # - issues_analysis: Issue patterns, bug trends, maintainer response patterns
  # - maintenance_analysis: Activity level, maintainer responsiveness, project health
  # - adoption_analysis: Integration difficulty, API design quality, migration complexity
  # - security_analysis: CVEs, security practices, vulnerability patterns

  #--------------------------------------
  # CALLBACKS
  #--------------------------------------

  before_validation :set_default_expiration, on: :create, if: -> { expires_at.nil? }

  #--------------------------------------
  # CLASS METHODS
  #--------------------------------------

  class << self
    # Check if we can create a new deep analysis today without exceeding budget
    # Includes pending cost reservations to prevent race conditions
    # @return [Boolean] true if within budget
    def can_create_today?
      remaining_budget_today > ESTIMATED_COST
    end

    # Calculate remaining budget for today INCLUDING pending reservations
    # This prevents race conditions where multiple requests check budget simultaneously
    # @return [Float] remaining budget in USD
    def remaining_budget_today
      # Actual costs from completed analyses
      spent = today.sum(:cost_usd) || 0

      # Pending cost reservations from in-flight analyses (prevents race condition)
      pending = AnalysisStatus
        .where(status: :processing)
        .where("created_at >= ?", Time.zone.now.beginning_of_day)
        .sum(:pending_cost_usd) || 0

      DAILY_BUDGET - spent - pending
    end

    # Get count of deep analyses created by user today
    # @param user [User] the user to check
    # @return [Integer] count of analyses today
    def count_for_user_today(user)
      return 0 if user.nil?

      where(user_id: user.id)
        .today
        .count
    end

    # Check if user has reached their daily rate limit
    # @param user [User] the user to check
    # @return [Boolean] true if user can create another analysis
    def user_can_create_today?(user)
      return false if user.nil?
      return true if user.admin? # Admin users bypass rate limit

      count_for_user_today(user) < RATE_LIMIT_PER_USER
    end
  end

  private

  #--------------------------------------
  # PRIVATE METHODS
  #--------------------------------------

  def set_default_expiration
    self.expires_at = DEFAULT_EXPIRATION_DAYS.days.from_now
  end
end
