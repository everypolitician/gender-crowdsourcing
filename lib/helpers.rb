# Sinatra route helpers.
module Helpers
  def current_user
    @current_user ||= User[session[:user_id]]
  end

  def country_counts
    @country_counts ||= CountryCount.to_hash(:country_code)
  end

  def completed_onboarding?
    current_user && current_user.has_completed_onboarding? ||
      session[:completed_onboarding]
  end

  def percent_complete(country)
    @percent_complete_countries ||= {}
    @percent_complete_countries[country.code] ||=
      begin
        country_count = country_counts[country.code]
        return 0 if country_count.nil?
        total_people = country_count.person_count
        complete_people = current_user.votes_dataset
          .where(person_uuid: CountryUUID.select(:uuid).where(country_slug: country.slug))
          .count
        total = (complete_people.to_f / total_people.to_f) * 100
        total < 100 ? total : 100
      end
  end

  def progress_word(percent)
    case
    when percent > 70
      'healthy'
    when percent > 10
      'unhealthy'
    else
      'dangerous'
    end
  end

  def motivational_quote
    settings.motivational_quotes.sample
  end

  def available_images(legislature)
    @available_images ||= begin
      index_txt_url = 'https://mysociety.github.io/politician-image-proxy/' \
        "#{legislature.country.slug}/#{legislature.slug}/index.txt"
      @available_images = open(index_txt_url).to_a.map(&:chomp)
    end
  rescue OpenURI::HTTPError => e
    warn "Couldn't retrieve list of available images: #{e.message}"
    []
  end

  def image_for?(legislature, person)
    available_images(legislature).include?(person[:id])
  end

  def image_for(legislature, person)
    [
      'https://mysociety.github.io/politician-image-proxy',
      legislature.country.slug,
      legislature.slug,
      URI.encode_www_form_component(person[:id]),
      '140x140.jpeg'
    ].join('/')
  end

  def previous_legislative_periods(legislative_period)
    legislature = legislative_period.legislature
    index = legislature.legislative_periods.index(legislative_period)
    legislature.legislative_periods[(index + 1)..-1]
  end

  def previous_legislative_period(legislative_period)
    previous_legislative_periods(legislative_period).first
  end
end
