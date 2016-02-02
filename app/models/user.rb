# Represents a user created from a social login.
class User < Sequel::Model
  one_to_many :responses
  one_to_many :votes

  def self.create_with_omniauth(auth)
    create do |user|
      user.provider = auth[:provider]
      user.uid = auth[:uid]
      user.name = auth[:info][:name] ||
        auth[:info][:nickname] ||
        auth[:info][:email]
    end
  end

  def recent_countries
    CountryUUID.recent_countries_for(self).map do |c|
      Everypolitician.country(slug: c.country_slug)
    end
  end

  def people_for(legislative_period)
    people = legislative_period.unique_people
    already_done = votes_dataset.map(:person_uuid)
    people.reject { |person| already_done.include?(person[:id]) }.shuffle
  end

  def legislative_periods_for(country, legislature)
    LegislativePeriod.enabled.where(
      country_code: country.code,
      legislature_slug: legislature.slug
    ).order(Sequel.desc(:start_date))
  end

  def legislative_period_for(country, legislature)
    legislative_periods_for(country, legislature).find { |lp| incomplete?(lp) }
  end

  def incomplete?(legislative_period)
    !legislative_period.missing? && people_for(legislative_period).any?
  end

  def has_completed_onboarding?
    completed_onboarding
  end

  def played_when_featured(country)
    featured_country = FeaturedCountry.first(country_code: country[:code])
    votes_dataset
      .join(:country_uuids, uuid: :person_uuid)
      .where(country_slug: country[:slug])
      .where{votes__created_at > featured_country.start_date}
      .where{votes__created_at < featured_country.end_date}
      .any?
  end

  def next_unfinished_term_for(legislature)
    legislature.legislative_periods.find do |lp|
      person_uuids = lp.csv.map { |p| p[:id] }.uniq
      already_done_count = votes_dataset.where(person_uuid: person_uuids).count
      already_done_count < person_uuids.size
    end
  end

  def record_vote(vote_data)
    vote = votes_dataset.first(person_uuid: vote_data[:person_uuid])
    if vote
      vote.update(choice: vote_data[:choice])
    else
      add_vote(vote_data)
    end
  end

  def votes_for_people(people, choice)
    votes_dataset.where(person_uuid: people.map { |p| p[:id] }, choice: choice)
  end
end
