class ApiKey < ApplicationRecord
  #--------------------------------------
  # ASSOCIATIONS
  #--------------------------------------

  belongs_to :user, optional: true  # System keys may not belong to a user

  #--------------------------------------
  # VALIDATIONS
  #--------------------------------------

  validates :name, presence: true, length: { maximum: 255 }
  validates :key_digest, presence: true, uniqueness: true

  #--------------------------------------
  # SCOPES
  #--------------------------------------

  scope :active, -> { where(revoked_at: nil) }
  scope :revoked, -> { where.not(revoked_at: nil) }
  scope :for_user, ->(user) { where(user: user) }
  scope :recent, -> { order(created_at: :desc) }

  #--------------------------------------
  # PUBLIC INSTANCE METHODS
  #--------------------------------------

  # Check if key is currently active (not revoked)
  def active?
    revoked_at.nil?
  end

  # Revoke this API key (soft delete)
  def revoke!
    update!(revoked_at: Time.current)
  end

  # Track usage of this key
  def track_usage!
    increment!(:request_count)
    touch(:last_used_at)
  end

  #--------------------------------------
  # CLASS METHODS
  #--------------------------------------

  class << self
    # Authenticate an API key
    # @param raw_key [String] The plain-text API key from the request
    # @return [ApiKey, nil] The ApiKey record if valid and active, nil otherwise
    def authenticate(raw_key)
      return nil if raw_key.blank?

      # Extract prefix from key (first 8 characters)
      prefix = raw_key[0...8]

      # Fast lookup: Find active keys with matching prefix
      # This reduces BCrypt checks from N keys to 1 key (99.99% of the time)
      candidate_keys = active.where(prefix: prefix)

      # Check each candidate (usually just 1)
      candidate_keys.find_each do |api_key|
        if BCrypt::Password.new(api_key.key_digest) == raw_key
          return api_key
        end
      rescue BCrypt::Errors::InvalidHash
        # Skip invalid digests
        next
      end

      # Fallback: Check legacy keys without prefix (for backward compatibility)
      # Remove this block once all keys have been migrated
      legacy_keys = active.where(prefix: nil)
      if legacy_keys.any?
        legacy_keys.find_each do |api_key|
          if BCrypt::Password.new(api_key.key_digest) == raw_key
            return api_key
          end
        rescue BCrypt::Errors::InvalidHash
          # Skip invalid digests
          next
        end
      end

      nil
    end

    # Generate a new API key
    # @param name [String] Human-readable name for this key
    # @param user [User, nil] Optional user this key belongs to
    # @return [Hash] { api_key: ApiKey record, raw_key: plain-text key (shown once) }
    def generate(name:, user: nil)
      # Generate secure random key (32 bytes = 64 hex chars)
      raw_key = SecureRandom.hex(32)

      # Extract prefix for fast lookup (first 8 chars)
      prefix = raw_key[0...8]

      # Hash the key with BCrypt (same as password hashing)
      key_digest = BCrypt::Password.create(raw_key)

      # Create the record
      api_key = create!(
        name: name,
        key_digest: key_digest,
        prefix: prefix,
        user: user
      )

      # Return both the record and the raw key
      # IMPORTANT: raw_key is only available here, never stored
      {
        api_key: api_key,
        raw_key: raw_key
      }
    end
  end
end
