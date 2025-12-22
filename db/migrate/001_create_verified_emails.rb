Sequel.migration do
  change do
    create_table(:verified_emails) do
      primary_key :id
      String :email_hash, null: false, unique: true
      String :organization_name
      DateTime :created_at, null: false
      DateTime :updated_at, null: false
    end
  end
end
