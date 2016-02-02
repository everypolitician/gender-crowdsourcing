Sequel.migration do
  change do
    alter_table(:featured_countries) do
      add_column :country_slug, String
    end
  end
end
