require 'sequel'

# Use LiteFS mount path in production, local db in development
db_path = ENV['LITEFS_DIR'] ? "#{ENV['LITEFS_DIR']}/roaster.db" : 'db/roaster.db'
DB = Sequel.connect("sqlite://#{db_path}")

# Auto-update timestamps
Sequel::Model.plugin :timestamps, update_on_create: true
