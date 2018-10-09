require 'sequel'
require 'sqlite3'
require 'sequel_enum'

RSpec.configure do |config|
  config.run_all_when_everything_filtered = true
  config.order = 'random'

  DB = Sequel.sqlite

  DB.create_table :conflicts do
    primary_key :id
    column :status, Integer
  end

  DB.create_table :items do
    primary_key :id
    column :name, String
    column :condition, Integer
    column :edition, Integer
    column :state, Integer
  end

  config.after(:suite) do
    DB.drop_table :items
    DB.drop_table :conflicts
  end
end
