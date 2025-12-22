ENV['RACK_ENV'] = 'test'

# SimpleCov must be started before any application code is loaded
require 'simplecov'
require 'simplecov-console'

SimpleCov.start do
  add_filter '/test/'
  add_filter '/config/'
  add_filter '/db/'

  # Use console formatter for terminal output with all files shown
  SimpleCov.formatter = SimpleCov::Formatter::Console

  # Configure console formatter to show all files
  SimpleCov::Formatter::Console.table_options = { max_width: 200 }
  SimpleCov::Formatter::Console.show_covered = true
end

require 'minitest/autorun'
require 'rack/test'
require 'sequel'

# Setup test database (override the constant before loading other files)
DB = Sequel.connect('sqlite://db/roaster_test.db')

# Configure Sequel plugins
Sequel::Model.plugin :timestamps, update_on_create: true

# Load models
require_relative '../app/models/organization'
require_relative '../app/models/verified_email'

# Run migrations for test database
Sequel.extension :migration
Sequel::Migrator.run(DB, 'db/migrate')

# Clear database before each test
class Minitest::Test
  def setup
    DB[:verified_emails].delete
    DB[:organizations].delete
  end
end
