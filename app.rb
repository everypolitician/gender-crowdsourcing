require 'bundler'
Bundler.require
Dotenv.load

require 'tilt/erubis'
require 'tilt/sass'
require 'active_support/core_ext'
require 'open-uri'
require 'csv'

$LOAD_PATH << File.expand_path('../lib', __FILE__)
$LOAD_PATH << File.expand_path('../', __FILE__)

configure do
  set :sessions, expire_after: 5.years
  set :session_secret, ENV['SESSION_SECRET']
  set :database, lambda {
    ENV['DATABASE_URL'] ||
      "postgres:///gender_crowdsourcing_#{environment}"
  }
  set :cache_client, Dalli::Client.new(
    (ENV['MEMCACHIER_SERVERS'] || 'localhost:11211').split(','),
    username: ENV['MEMCACHIER_USERNAME'],
    password: ENV['MEMCACHIER_PASSWORD'],
    failover: true,
    socket_timeout: 1.5,
    socket_failure_delay: 0.2
  )
  set :static_cache_control, [:public, max_age: 5.minutes] if production?
  set :motivational_quotes, YAML.load_file('config/motivational_quotes.yml')
end

require 'helpers'
require 'app/models'
require 'app/jobs'
require 'csv_export'
require 'vote_counts'
require 'vote_consensus'

helpers Helpers

use Rack::Flash

use OmniAuth::Builder do
  provider :twitter, ENV['TWITTER_CONSUMER_KEY'], ENV['TWITTER_CONSUMER_SECRET']
  provider :facebook, ENV['FACEBOOK_APP_ID'], ENV['FACEBOOK_APP_SECRET']
  provider :github, ENV['GITHUB_CLIENT_ID'], ENV['GITHUB_CLIENT_SECRET']
  provider :google_oauth2, ENV['GOOGLE_CLIENT_ID'], ENV['GOOGLE_CLIENT_SECRET']
  provider :linkedin, ENV['LINKEDIN_CLIENT_ID'], ENV['LINKEDIN_CLIENT_SECRET']
end

get '/*.css' do |filename|
  cache_control :public, max_age: 5.minutes if settings.production?
  scss :"sass/#{filename}"
end

get '/' do
  @leaders = Response.leaders
  if current_user
    erb :home_loggedin
  else
    erb :home_anonymous
  end
end

get '/login' do
  erb :login
end

get '/about' do
  erb :about
end

post '/event_handler' do
  settings.cache_client.delete('countries.json')
  UpdateCacheJob.perform_async
  'ok'
end

get '/logout' do
  session[:user_id] = nil
  flash[:notice] = 'You have been logged out'
  redirect to('/')
end

%w(get post).each do |method|
  send(method, '/auth/:provider/callback') do
    auth = request.env['omniauth.auth']
    user = User.first(provider: auth[:provider], uid: auth[:uid]) ||
           User.create_with_omniauth(auth)
    if session[:completed_onboarding]
      user.completed_onboarding = true
      user.save
    end
    session[:user_id] = user.id
    flash[:notice] = 'Signed in!'
    redirect to('/countries')
  end
end

get '/auth/failure' do
  logger.info "Auth failure: #{params[:message]}"
  flash[:notice] = "There was a problem authenticating you. Please try again."
  redirect '/login'
end

get '/onboarding' do
  redirect to('/countries') if completed_onboarding?
  erb :onboarding
end

get '/onboarding-complete' do
  session[:completed_onboarding] = true
  if current_user
    current_user.completed_onboarding = true
    current_user.save
  end
  redirect to('/countries')
end

before '/countries*' do
  redirect to('/onboarding') unless completed_onboarding?
  pass if current_user
  flash[:alert] = 'Please sign in'
  redirect to('/login')
end

get '/countries' do
  @countries = Country.all
  @recent_countries = current_user.responses_dataset.recent_countries
  current_featured_country = FeaturedCountry.current
  if current_featured_country
    @featured_country = Country.find_by_code(current_featured_country.country_code)
  end
  erb :countries
end

get '/countries/:country' do
  @country = Country.find_by_slug(params[:country])
  if @country[:legislatures].length == 1
    legislature = @country[:legislatures].first
    redirect to("/countries/#{@country[:slug]}/legislatures/#{legislature[:slug]}")
  else
    erb :country
  end
end

get '/countries/:country/legislatures/:legislature' do
  @country = Country.find_by_slug(params[:country])
  @legislature = @country.legislature(params[:legislature])
  @legislative_period = current_user.legislative_period_for(@country, @legislature)
  return erb :congratulations unless @legislative_period
  @people = current_user.people_for(@legislative_period)
  erb :term
end

get '/_stats' do
  @players = Response.join(:users, id: :user_id).group_and_count(:users__id)
  erb :stats
end

post '/responses' do
  begin
    current_user.record_response(params[:response])
    'ok'
  rescue Sequel::UniqueConstraintViolation
    halt 403, 'Decision already recorded for this politician'
  end
end

get '/export/:country_slug/:legislature_slug' do |country_slug, legislature_slug|
  content_type 'text/csv;charset=utf-8'
  country = Country.find_by_slug(country_slug)
  legislative_period = LegislativePeriod.first(
    country_code: country[:code],
    legislature_slug: legislature_slug
  )
  halt 500, "Couldn't find legislative period for #{country_slug} - #{legislature_slug}" if legislative_period.nil?
  legacy_ids = LegacyIdMapper.new(legislative_period.popolo)

  vote_counts = VoteCounts.new(country[:code], legislature_slug, legacy_ids.reverse_map)
  CsvExport.new(vote_counts).to_csv
end
