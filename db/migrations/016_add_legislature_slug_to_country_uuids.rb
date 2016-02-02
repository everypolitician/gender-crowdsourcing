Sequel.migration do
  change do
    alter_table(:country_uuids) do
      add_column :legislature_slug, String, null: false
      drop_constraint :country_uuids_uuid_country_slug_key
      add_unique_constraint [:uuid, :country_slug, :legislature_slug]
    end
  end
end
