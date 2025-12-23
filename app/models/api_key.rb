# Table: api_keys
# --------------------------------------------------------
# Columns:
#  id           | INTEGER      | PRIMARY KEY AUTOINCREMENT
#  name         | varchar(255) | NOT NULL
#  key_hash     | varchar(255) | NOT NULL
#  key_prefix   | varchar(8)   | NOT NULL
#  created_at   | timestamp    | NOT NULL
#  updated_at   | timestamp    | NOT NULL
#  last_used_at | timestamp    |
# Indexes:
#  api_keys_key_hash_index   | UNIQUE (key_hash)
#  api_keys_key_prefix_index | (key_prefix)
# --------------------------------------------------------

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

    # Update last_used_at timestamp
    api_key&.update(last_used_at: Time.now)

    api_key
  end

  def masked_key
    "#{key_prefix}#{'*' * 56}"
  end
end
