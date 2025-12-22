require 'digest'
require 'securerandom'

class ApiKey < Sequel::Model
  def self.generate(name)
    # Generate a random API key (32 bytes = 64 hex characters)
    raw_key = SecureRandom.hex(32)

    # Create prefix for easy identification (first 8 chars)
    prefix = raw_key[0, 8]

    # Hash the full key for storage
    key_hash = Digest::SHA256.hexdigest(raw_key)

    # Create the API key record
    api_key = create(
      name: name,
      key_hash: key_hash,
      key_prefix: prefix
    )

    # Return the API key record and the raw key (only time it's visible)
    { api_key: api_key, raw_key: raw_key }
  end

  def self.authenticate(raw_key)
    return nil if raw_key.nil? || raw_key.empty?

    key_hash = Digest::SHA256.hexdigest(raw_key)
    api_key = first(key_hash: key_hash)

    if api_key
      # Update last_used_at timestamp
      api_key.update(last_used_at: Time.now)
    end

    api_key
  end

  def masked_key
    "#{key_prefix}#{'*' * 56}"
  end
end
