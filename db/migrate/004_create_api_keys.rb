Sequel.migration do
  change do
    create_table(:api_keys) do
      primary_key :id
      String :name, null: false
      String :key_hash, null: false
      String :key_prefix, size: 8, null: false
      DateTime :created_at, null: false
      DateTime :updated_at, null: false
      DateTime :last_used_at

      index :key_hash, unique: true
      index :key_prefix
    end
  end
end
