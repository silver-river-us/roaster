# Table: organizations
# ---------------------------------------------------------
# Columns:
#  id            | INTEGER      | PRIMARY KEY AUTOINCREMENT
#  name          | varchar(255) | NOT NULL
#  username      | varchar(255) | NOT NULL
#  password_hash | varchar(255) | NOT NULL
#  created_at    | timestamp    | NOT NULL
#  updated_at    | timestamp    | NOT NULL
# Indexes:
#  sqlite_autoindex_organizations_1 | UNIQUE (name)
#  sqlite_autoindex_organizations_2 | UNIQUE (username)
# ---------------------------------------------------------

require 'bcrypt'

class Organization < Sequel::Model
  def password=(new_password)
    self.password_hash = BCrypt::Password.create(new_password) if new_password && !new_password.empty?
  end

  def password_match?(password)
    return false unless password_hash

    BCrypt::Password.new(password_hash) == password
  end

  def self.authenticate(username, password)
    org = find(username: username)
    org&.password_match?(password) ? org : nil
  end

  # Allow creating organizations with password in one call
  def self.create_with_password(attrs)
    password = attrs.delete(:password)
    org = new(attrs)
    org.password = password if password
    org.save
    org
  end
end
