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
