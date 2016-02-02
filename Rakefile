require 'dotenv/tasks'
task app: :dotenv do
  require_relative './app'
end

namespace :db do
  desc 'Run migrations'
  task :migrate, [:version] => :app do |_t, args|
    require 'sequel'
    Sequel.extension :migration
    db = Sinatra::Application.database
    if args[:version]
      puts "Migrating to version #{args[:version]}"
      Sequel::Migrator.run(db, 'db/migrations', target: args[:version].to_i)
    else
      puts 'Migrating to latest'
      Sequel::Migrator.run(db, 'db/migrations')
    end
  end
end

require 'rake/testtask'
Rake::TestTask.new do |t|
  t.libs << 'spec'
  t.test_files = FileList['spec/*_spec.rb']
  t.verbose = true
end

require 'rubocop/rake_task'
RuboCop::RakeTask.new

task default: :test

task cache: ['cache:country_person_counts', 'cache:legislative_periods']

namespace :cache do
  task country_person_counts: :app do
    UpdateCacheJob.new.cache_country_person_counts
  end

  task legislative_periods: :app do
    UpdateCacheJob.new.cache_legislative_periods
  end
end

task add_country_slug_to_featured_countries: :app do
  FeaturedCountry.each do |fc|
    country = Everypolitician.country(code: fc.country_code)
    fc.update(country_slug: country.slug)
  end
end

def id_mapper(country_code, legislature_slug)
  @mappers ||= {}
  @mappers[country_code] ||= {}
  @mappers[country_code][legislature_slug] ||= begin
    legislature = Everypolitician.country(code: country_code).legislature(slug: legislature_slug)
    LegacyIdMapper.new(legislature.popolo)
  end
end

task migrate_responses_to_votes: :app do
  db = Sinatra::Application.database
  responses = db[:responses]
    .select(:user_id, :politician_id, :choice, :country_code, :legislature_slug, :responses__created_at, :responses__updated_at)
    .join(:legislative_periods, id: :legislative_period_id)
    .order(Sequel.desc(:responses__created_at))
  warn "Found #{responses.count} responses to migrate to votes"
  responses.each do |response|
    legacy_id_mapper = id_mapper(response[:country_code], response[:legislature_slug])
    begin
      db[:votes].insert(
        user_id: response[:user_id],
        person_uuid: legacy_id_mapper.reverse_map[response[:politician_id]],
        choice: response[:choice],
        created_at: response[:created_at],
        updated_at: response[:updated_at]
      )
    rescue Sequel::UniqueConstraintViolation => e
      warn e
    end
  end
end
