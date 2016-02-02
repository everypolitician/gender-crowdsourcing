require 'legacy_id_mapper'

class LegislativePeriod < Sequel::Model
  one_to_many :responses

  dataset_module do
    def for_country_code(country_code)
      where(country_code: country_code).order(Sequel.desc(:start_date))
    end

    def enabled
      where(disabled: false)
    end
  end

  def missing?
    legislative_period.nil?
  end

  def disable!
    self.disabled = true
    save
  end

  def name
    legislative_period[:name]
  end

  def country
    @country ||= Everypolitician.country(code: country_code)
  end

  def legislature
    @legislature ||= country.legislature(slug: legislature_slug)
  end

  def legislative_period
    @legislative_period ||= legislature.legislative_periods.find do |lp|
      lp[:id] == legislative_period_id
    end
  end

  def cache_key
    @cache_key ||= [
      legislature.sha,
      legislative_period[:csv],
      legislature.lastmod
    ].join(':')
  end

  def csv
    Sinatra::Application.cache_client.fetch(cache_key, 1.month) do
      csv_url = 'https://cdn.rawgit.com/everypolitician/everypolitician-data/' \
        "#{legislature.sha}/#{legislative_period[:csv]}"
      CSV.parse(open(csv_url).read, headers: true, header_converters: :symbol)
    end
  end

  def available_images
    unless @available_images
      index_txt_url = 'https://mysociety.github.io/politician-image-proxy/' \
        "#{country.slug}/#{legislature_slug}/index.txt"
      @available_images = open(index_txt_url).to_a.map(&:chomp)
    end
    @available_images
  rescue OpenURI::HTTPError => e
    warn "Couldn't retrieve list of available images: #{e.message}"
    []
  end

  def unique_people
    csv.map(&:to_h).to_a.uniq { |person| person[:id] }
  end

  def already_have_gender
    unique_people.count { |person| person[:gender] }
  end

  def previous_legislative_period
    previous_legislative_periods.first
  end

  def previous_legislative_periods
    LegislativePeriod
      .enabled
      .where(country_code: country.code, legislature_slug: legislature.slug)
      .order(Sequel.desc(:start_date))
      .where('start_date < ?', start_date)
  end
end
