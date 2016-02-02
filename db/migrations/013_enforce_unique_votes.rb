Sequel.migration do
  change do
    alter_table(:votes) do
      add_index [:user_id, :person_uuid], unique: true
    end
  end
end
