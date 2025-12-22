require 'digest'
require 'csv'

class VerifiedEmail < Sequel::Model
  def self.hash_email(email)
    Digest::SHA256.hexdigest(email.downcase.strip)
  end

  def self.verified?(email)
    email_hash = hash_email(email)
    where(email_hash: email_hash).any?
  end

  def self.import_from_csv(csv_path, organization_name = nil)
    imported = 0
    duplicates = 0

    CSV.foreach(csv_path, headers: true) do |row|
      email = row['email']&.strip
      next if email.nil? || email.empty?

      email_hash = hash_email(email)

      begin
        create(
          email_hash: email_hash,
          organization_name: organization_name
        )
        imported += 1
      rescue Sequel::UniqueConstraintViolation
        duplicates += 1
      end
    end

    { imported: imported, duplicates: duplicates }
  end
end
