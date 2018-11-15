class UpdateCacheJob
  include Sidekiq::Worker

  def perform
    Everypolitician.countries.each do |country|
      puts "Caching #{country[:name]}"
      country.legislatures.each do |legislature|
        legislature.popolo.persons.each do |person|
          country_uuid = CountryUUID.find_or_create(
            country_slug: country.slug,
            legislature_slug: legislature.slug,
            uuid: person[:id]
          )
          country_uuid.update(gender: person[:gender])
        end
        ep_ids = legislature.popolo.persons.map(&:id)
        gb_ids = CountryUUID.where(country_slug: country.slug, legislature_slug: legislature.slug).map(&:uuid)
        missing_uuids = gb_ids - ep_ids
        Vote.where(person_uuid: missing_uuids).delete
        CountryUUID.where(uuid: missing_uuids).delete
      end
    end
  end
end
