Sequel.migration do
  change do
    create_table(:votes) do
      primary_key :id
      foreign_key :user_id, :users, null: false, index: true
      String :person_uuid, null: false
      String :choice, null: false
      DateTime :created_at
      DateTime :updated_at
    end
  end
end
