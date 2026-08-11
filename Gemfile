source "https://rubygems.org"

gem "rails", "~> 8.1.3"
gem "propshaft"
gem "puma", ">= 5.0"
gem "haml-rails"
gem "omniauth"
gem "omniauth-rails_csrf_protection"
gem "omniauth_openid_connect"
gem "rest-client"
gem "request_store"
gem "tzinfo-data", platforms: %i[ windows jruby ]

group :development, :test do
  gem "brakeman", require: false
  gem "debug", platforms: %i[ mri windows ], require: "debug/prelude"
  gem "rubocop-rails-omakase", require: false
end

unless ENV["NO_INTERNAL"]
  local_gemfile = File.expand_path("Gemfile.internal", __dir__)
  eval_gemfile(local_gemfile) if File.exist?(local_gemfile)
end
