require 'bcrypt'

class Organization < Sequel::Model
  def password=(new_password)
    self.password_hash = BCrypt::Password.create(new_password)
  end

  def authenticate(password)
    BCrypt::Password.new(password_hash) == password
  end

  def self.authenticate(username, password)
    org = find(username: username)
    org&.authenticate(password) ? org : nil
  end
end
