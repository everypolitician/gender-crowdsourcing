class Vote < Sequel::Model
  many_to_one :user

  dataset_module do
    def leaders(limit = 10)
      # Users get double points for votes created while a featured country
      # is active.
      double_points = {
        :votes__created_at => :featured_countries__start_date..:featured_countries__end_date
      }
      score = Sequel.case({double_points => 2}, 1)
      select(:users__id, :users__name)
        .select_append{sum(score).as(:count)}
        .join(:users, id: :votes__user_id)
        .join(:country_uuids, uuid: :votes__person_uuid)
        .left_outer_join(:featured_countries, country_slug: :country_uuids__country_slug)
        .group(:users__id, :users__name)
        .order(Sequel.desc(:count))
        .limit(limit)
        .where{votes__created_at > 1.month.ago}
    end
  end
end
