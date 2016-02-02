Sequel.migration do
  change do
    create_table(:country_uuids) do
      primary_key :id
      String :uuid, null: false
      String :country_slug, null: false
      DateTime :created_at
      DateTime :updated_at
      unique [:uuid, :country_slug]
    end
  end
end
