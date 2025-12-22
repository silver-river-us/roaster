require 'sequel'

DB = Sequel.connect('sqlite://db/roaster.db')

# Auto-update timestamps
Sequel::Model.plugin :timestamps, update_on_create: true
