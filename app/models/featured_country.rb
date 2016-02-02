class FeaturedCountry < Sequel::Model
  dataset_module do
    def current
      where{start_date <= DateTime.now}
        .where{end_date >= DateTime.now}
        .first
    end

    def current=(country_code)
      db.transaction do
        current.update(end_date: DateTime.now) if current
        country = Everypolitician.country(code: country_code)
        raise ArgumentError, "Invalid country code: #{country_code}" if country.nil?
        if FeaturedCountry.where(country_code: country_code).any?
          raise ArgumentError, "This country has already been featured. See http://git.io/vcO2x"
        end
        FeaturedCountry.create(
          country_code: country.code,
          country_slug: country.slug,
          start_date: DateTime.now,
          end_date: 1.month.from_now
        )
      end
    end
  end
end
