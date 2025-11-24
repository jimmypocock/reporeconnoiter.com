source "https://rubygems.org"

# Bundle edge Rails instead: gem "rails", github: "rails/rails", branch: "main"
gem "rails", "~> 8.1.1"
# The modern asset pipeline for Rails [https://github.com/rails/propshaft]
gem "propshaft"
# Use postgresql as the database for Active Record
gem "pg", "~> 1.1"
# Use the Puma web server [https://github.com/puma/puma]
gem "puma", ">= 5.0"
# Use JavaScript with ESM import maps [https://github.com/rails/importmap-rails]
gem "importmap-rails"
# Hotwire's SPA-like page accelerator [https://turbo.hotwired.dev]
gem "turbo-rails"
# Hotwire's modest JavaScript framework [https://stimulus.hotwired.dev]
gem "stimulus-rails"
# Use Tailwind CSS [https://github.com/rails/tailwindcss-rails]
gem "tailwindcss-rails"
# Heroicons - SVG icon library [https://github.com/adamcrown/heroicons-ruby]
gem "heroicon"
# Build JSON APIs with ease [https://github.com/rails/jbuilder]
gem "jbuilder"
# GitHub API client [https://github.com/octokit/octokit.rb]
gem "octokit"
# OpenAI API client [https://github.com/openai/openai-ruby]
gem "openai", "~> 0.36.1"
# Faraday retry middleware
gem "faraday-retry"
# Ruby OpenSSL wrapper - pinned to 3.3.1+ for OpenSSL 3.6 CRL fix
gem "openssl", ">= 3.3.1"
# Pagination [https://github.com/ddnexus/pagy]
gem "pagy"
# Authentication [https://github.com/heartcombo/devise]
gem "devise"
# GitHub OAuth [https://github.com/omniauth/omniauth-github]
gem "omniauth-github"
# OmniAuth CSRF protection [https://github.com/cookpad/omniauth-rails_csrf_protection]
gem "omniauth-rails_csrf_protection"
# Rate limiting and throttling [https://github.com/rack/rack-attack]
gem "rack-attack"
# Error tracking [https://github.com/getsentry/sentry-ruby]
gem "sentry-ruby"
gem "sentry-rails"

# Use Active Model has_secure_password [https://guides.rubyonrails.org/active_model_basics.html#securepassword]
gem "bcrypt", "~> 3.1.7"
# JSON Web Token for API authentication [https://github.com/jwt/ruby-jwt]
gem "jwt"

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: %i[ windows jruby ]

# Use the database-backed adapters for Rails.cache, Active Job, and Action Cable
gem "solid_cache"
gem "solid_queue"
gem "solid_cable"

# Mission Control for job monitoring [https://github.com/basecamp/mission_control-jobs]
gem "mission_control-jobs"

# Swagger UI for interactive API documentation [https://github.com/rswag/rswag]
gem "rswag-ui"

# CORS support for API access from different origins [https://github.com/cyu/rack-cors]
gem "rack-cors"

# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap", require: false

# Deploy this application anywhere as a Docker container [https://kamal-deploy.org]
gem "kamal", require: false

# Add HTTP asset caching/compression and X-Sendfile acceleration to Puma [https://github.com/basecamp/thruster/]
gem "thruster", require: false

# Use Active Storage variants [https://guides.rubyonrails.org/active_storage_overview.html#transforming-images]
gem "image_processing", "~> 1.2"

group :development, :test do
  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  gem "debug", platforms: %i[ mri windows ], require: "debug/prelude"

  # Load environment variables from .env file [https://github.com/bkeepers/dotenv]
  gem "dotenv-rails"

  # Audits gems for known security defects (use config/bundler-audit.yml to ignore issues)
  gem "bundler-audit", require: false

  # Static analysis for security vulnerabilities [https://brakemanscanner.org/]
  gem "brakeman", require: false

  # Omakase Ruby styling [https://github.com/rails/rubocop-rails-omakase/]
  gem "rubocop-rails-omakase", require: false
end

group :development do
  # Use console on exceptions pages [https://github.com/rails/web-console]
  gem "web-console"
end

group :test do
  # Use system testing [https://guides.rubyonrails.org/testing.html#system-testing]
  gem "capybara"
  gem "selenium-webdriver"

  # Block all HTTP requests during tests to prevent accidental API calls
  gem "webmock"

  # Validate API responses against OpenAPI spec
  gem "committee"

  # Stub environment variables in tests
  gem "climate_control"
end
