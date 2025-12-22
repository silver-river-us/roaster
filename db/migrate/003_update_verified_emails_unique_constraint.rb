Sequel.migration do
  up do
    # SQLite doesn't support dropping constraints directly, so we need to recreate the table
    create_table(:verified_emails_new) do
      primary_key :id
      String :email_hash, null: false
      String :organization_name
      DateTime :created_at, null: false
      DateTime :updated_at, null: false

      index [:email_hash, :organization_name], unique: true
    end

    # Copy data from old table
    run 'INSERT INTO verified_emails_new SELECT * FROM verified_emails'

    # Drop old table and rename new one
    drop_table(:verified_emails)
    rename_table(:verified_emails_new, :verified_emails)
  end

  down do
    create_table(:verified_emails_new) do
      primary_key :id
      String :email_hash, null: false, unique: true
      String :organization_name
      DateTime :created_at, null: false
      DateTime :updated_at, null: false
    end

    run 'INSERT INTO verified_emails_new SELECT * FROM verified_emails'
    drop_table(:verified_emails)
    rename_table(:verified_emails_new, :verified_emails)
  end
end
