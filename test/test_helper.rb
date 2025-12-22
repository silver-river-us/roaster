ENV['RACK_ENV'] = 'test'

require 'minitest/autorun'
require 'rack/test'
require 'sequel'

# Setup test database (override the constant before loading other files)
DB = Sequel.connect('sqlite://db/roaster_test.db')

# Configure Sequel plugins
Sequel::Model.plugin :timestamps, update_on_create: true

# Load models
require_relative '../models/verified_email'

# Run migrations for test database
Sequel.extension :migration
Sequel::Migrator.run(DB, 'db/migrate')

# Clear database before each test
class Minitest::Test
  def setup
    DB[:verified_emails].delete
  end
end
