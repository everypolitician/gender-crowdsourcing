Sinatra::Application.database.extension(:connection_validator)
Sinatra::Application.database.pool.connection_validation_timeout = -1

Sequel::Model.plugin :timestamps
Sequel::Model.plugin :validation_helpers

require 'app/models/user'
require 'app/models/response'
require 'app/models/country_count'
require 'app/models/legislative_period'
require 'app/models/featured_country'
require 'app/models/vote'
require 'app/models/country_uuid'
