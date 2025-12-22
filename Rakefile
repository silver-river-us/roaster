require 'rake/testtask'

Rake::TestTask.new(:test) do |t|
  t.libs << 'test'
  t.test_files = FileList['test/**/**/test_*.rb']
  t.verbose = true
  t.warning = false
end

task default: :test

namespace :db do
  desc 'Run migrations'
  task :migrate do
    require 'sequel'
    # Use LiteFS mount path in production, local db in development
    db_path = ENV['LITEFS_DIR'] ? "#{ENV['LITEFS_DIR']}/roaster.db" : 'db/roaster.db'
    db = Sequel.connect("sqlite://#{db_path}")
    require 'sequel/extensions/migration'
    Sequel::Migrator.run(db, 'db/migrate')
    puts 'Migrations completed'
  end

  desc 'Run migrations for test database'
  task :migrate_test do
    require 'sequel'
    db = Sequel.connect('sqlite://db/roaster_test.db')
    require 'sequel/extensions/migration'
    Sequel::Migrator.run(db, 'db/migrate')
    puts 'Test database migrations completed'
  end

  desc 'Import emails from CSV'
  task :import, [:csv_path, :organization] do |_t, args|
    require_relative 'config/database'
    require_relative 'models/verified_email'

    unless args[:csv_path]
      puts 'Usage: rake db:import[path/to/emails.csv,OrganizationName]'
      exit 1
    end

    result = VerifiedEmail.import_from_csv(args[:csv_path], args[:organization])
    puts "Imported: #{result[:imported]}"
    puts "Duplicates skipped: #{result[:duplicates]}"
  end

  desc 'Check if email is verified'
  task :check, [:email] do |_t, args|
    require_relative 'config/database'
    require_relative 'models/verified_email'

    unless args[:email]
      puts 'Usage: rake db:check[user@example.com]'
      exit 1
    end

    if VerifiedEmail.verified?(args[:email])
      puts '✓ Email is verified'
    else
      puts '✗ Email is not verified'
    end
  end
end
