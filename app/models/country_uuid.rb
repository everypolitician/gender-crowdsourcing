class CountryUUID < Sequel::Model
  dataset_module do
    def recent_countries_for(user)
      total_people = CountryUUID.select{count(:*){}}.where(country_slug: :u__country_slug)
      from(:country_uuids___u)
        .select_group(:country_slug)
        .select_append{max(votes__created_at).as(:last_vote)}
        .select_append(Sequel.function(:count).*.as(:votes))
        .select_append(total_people.as(:total_people))
        .join(:votes, person_uuid: :uuid)
        .where(user_id: user.id)
        .having('count(*) < ?', total_people)
        .order(:country_slug)
        .limit(5)
    end
  end
end
