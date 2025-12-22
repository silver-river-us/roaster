Sequel.migration do
  change do
    create_table(:organizations) do
      primary_key :id
      String :name, null: false, unique: true
      String :username, null: false, unique: true
      String :password_hash, null: false
      DateTime :created_at, null: false
      DateTime :updated_at, null: false
    end
  end
end
