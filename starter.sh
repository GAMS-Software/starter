#! /bin/bash

# Ask the name of the service to create
echo "👋 Welcome to the Rails Starter!"
echo "🤔 What's the name of the service you want to create?"
read SERVICE_NAME

# Ask if user want to activate lato
LATO_ACTIVATED=false
echo "🤔 Do you want to activate lato? (y/n)"
read ACTIVATE_LATO
if [ "$ACTIVATE_LATO" = "y" ]; then
  LATO_ACTIVATED=true
fi

# Ask if user want to activate litestack
LITESTACK_ACTIVATED=false
echo "🤔 Do you want to activate litestack? (y/n)"
read ACTIVATE_LITESTACK
if [ "$ACTIVATE_LITESTACK" = "y" ]; then
  LITESTACK_ACTIVATED=true
fi

# Ask if user want to activate redis
REDIS_ACTIVATED=false
if [ "$LITESTACK_ACTIVATED" = false ]; then
  echo "🤔 Do you want to activate redis? (y/n)"
  read ACTIVATE_REDIS
  if [ "$ACTIVATE_REDIS" = "y" ]; then
    REDIS_ACTIVATED=true
  fi
fi

# Ask if user want to activate sidekiq (only if redis is activated)
SIDEKIQ_ACTIVATED=false
if [ "$REDIS_ACTIVATED" = true ]; then
  echo "🤔 Do you want to activate sidekiq? (y/n)"
  read ACTIVATE_SIDEKIQ
  if [ "$ACTIVATE_SIDEKIQ" = "y" ]; then
    SIDEKIQ_ACTIVATED=true
  fi
fi

# Create new rails app using service name
echo "⏳ Creating new rails app..."
rails new $SERVICE_NAME
echo "✅ New rails app created successfully!"

# Change directory to service name
cd $SERVICE_NAME

# Create a Procfile file for the service
echo "⏳ Creating Procfile file..."
echo "web: bundle exec rails s -b 0.0.0.0 -e \$RAILS_ENV" > Procfile

# Create a custom README.md file
echo "⏳ Creating README.md file..."
echo "# $SERVICE_NAME

## Description

This is a [Rails](https://rubyonrails.org/) application.

## Getting Started

### Prerequisites

- Ruby installed
- Rails gem installed

### Installation

1. Clone the repo with **git clone**

2. Go to the project folder with **cd $SERVICE_NAME**

3. Install dependencies with **bundle install**

4. Create the database with **rails db:create**

5. Run the migrations with **rails db:migrate**

6. Run seed data with **rails db:seed**

### Usage

- Start the app with **rails s**

- Run rails console with **rails c**

- Run rails tasks with **rails TASK_NAME**

- Run tests with **rails test**

The homepage of the app will be available at [http://localhost:3000](http://localhost:3000)
The admin panel of the app will be available at [http://localhost:3000/adm](http://localhost:3000/adm)

You can login in the admin panel with the following credentials:
- email: admin@mail.com
- password: Password1!
" > README.md
echo "✅ README.md file created successfully!"

# Configure I18n in application.rb
echo "⏳ Configuring I18n in application.rb..."
# set default locale to en (add line after config.load_defaults 7.0)
sed -i -e 's/config.load_defaults 7.0/config.load_defaults 7.0\n    config.i18n.default_locale = :en/g' config/application.rb
# set available locales to en and it (add line after config.i18n.default_locale = :en)
sed -i -e 's/config.i18n.default_locale = :en/config.i18n.default_locale = :en\n    config.i18n.available_locales = [:en, :it]/g' config/application.rb
# remove file application.rb-e
rm config/application.rb-e
echo "✅ I18n configured in application.rb successfully!"

# LATO INSTALLATION
##

if [ "$LATO_ACTIVATED" = true ]; then

# Add lato gem to Gemfile and add it's dependencies
echo "⏳ Adding lato gem to Gemfile and add it's dependencies..."
# add lato gem
echo "
# Create custom web ui using lato gem [https://github.com/lato-gam/lato]
gem 'lato'" >> Gemfile
# add version 1.3.3 to turbo-rails gem
sed -i -e 's/gem "turbo-rails"/gem "turbo-rails"/g' Gemfile
# uncomment the sassc-rails gem
sed -i -e 's/# gem "sassc-rails"/gem "sassc-rails"/g' Gemfile
# remove file Gemfile-e
rm Gemfile-e
echo "✅ lato gem added to Gemfile and it's dependencies added successfully!"

# Replace application.css with application.scss
echo "⏳ Replacing application.css with application.scss..."
rm app/assets/stylesheets/application.css
touch app/assets/stylesheets/application.scss
echo "✅ application.css replaced with application.scss successfully!"

# Import lato styles in application.scss
echo "⏳ Importing lato styles in application.scss..."
echo "@import 'lato/application';" >> app/assets/stylesheets/application.scss
echo "✅ lato styles imported in application.scss successfully!"

# Import lato javascript in application.js
echo "⏳ Importing lato javascript in application.js..."
echo "import \"lato/application\";" >> app/javascript/application.js
echo "✅ lato javascript imported in application.js successfully!"

# Edit routes file to mount lato engine
echo "⏳ Editing routes file to mount lato engine..."
sed -i -e 's/Rails.application.routes.draw do/Rails.application.routes.draw do\n  mount Lato::Engine => "\/adm"/g' config/routes.rb
rm config/routes.rb-e
echo "✅ Routes file edited successfully!"

# Create a lato_config.rb initializer to configure lato
echo "⏳ Creating lato_config.rb initializer..."
touch config/initializers/lato_config.rb
echo "Lato.configure do |config|
  config.application_title = '$SERVICE_NAME'
  config.application_version = '1.0.0'
  config.application_company_name = 'Lato Team'
  config.application_company_url = 'https://github.com/lato-gam'

  # Set custom root path for session after login
  # config.session_root_path = :dashboard_path

  # Disable signup page to avoid new users registration
  config.auth_disable_signup = true 

  # Setup legal settings
  config.legal_privacy_policy_url = '/privacy-policy'
  config.legal_terms_and_conditions_url = '/terms-and-conditions'
  config.legal_privacy_policy_version = 1
  config.legal_terms_and_conditions_version = 1

  # Setup email settings
  config.email_from = '$SERVICE_NAME <noreply@mail.com>'

  # Please check source code for more configuration options:
  # https://github.com/lato-gam/lato/blob/main/lib/lato/config.rb
end" > config/initializers/lato_config.rb
echo "✅ lato_config.rb initializer created successfully!"

# Edit seeds file to create a default lato user
echo "⏳ Editing seeds file to create a default lato user..."
echo "
puts 'Creating default admin user...'
Lato::User.create!(
  first_name: 'Admin',
  last_name: 'Admin',
  email: 'admin@mail.com',
  password: 'Password1!',
  password_confirmation: 'Password1!',
  accepted_privacy_policy_version: 1,
  accepted_terms_and_conditions_version: 1
)
puts 'Default lato user created successfully!'" >> db/seeds.rb

fi

# LITESTACK INSTALLATION
##

if [ "$LITESTACK_ACTIVATED" = true ]; then

# Add litestack gem to Gemfile
echo "⏳ Adding litestack gem to Gemfile..."
# add litestack gem
echo "
# Create custom web ui using litestack gem [https://github.com/oldmoe/litestack]
gem 'litestack'" >> Gemfile
# remove file Gemfile-e
rm Gemfile-e
echo "✅ litestack gem added to Gemfile successfully!"

# Run bundle install
echo "⏳ Running bundle install..."
bundle install
echo "✅ bundle install completed successfully!"

# Run litestack install generator
echo "⏳ Running litestack install generator..."
rails g litestack:install
echo "✅ litestack install generator completed successfully!"

fi

# REDIS INSTALLATION
##

if [ "$REDIS_ACTIVATED" = true ]; then

# Activate redis gem on Gemfile
echo "⏳ Activating redis gem on Gemfile..."
# uncomment row # gem "redis", "~> 4.0"
sed -i -e 's/# gem "redis", "~> 4.0"/gem "redis", "~> 4.0"/g' Gemfile
# remove file Gemfile-e
rm Gemfile-e
echo "✅ Redis gem activated on Gemfile successfully!"

# Activate redis in development environment
echo "⏳ Activating redis in development environment..."
# replace "config.cache_store = :null_store" with "config.cache_store = :redis_cache_store, { url: ENV.fetch('REDIS_URL', 'redis://localhost:6379/0') }"
sed -i -e 's/config.cache_store = :null_store/config.cache_store = :redis_cache_store, { url: ENV.fetch("REDIS_URL", "redis:\/\/localhost:6379\/0") }/g' config/environments/development.rb
rm config/environments/development.rb-e
echo "✅ Redis activated in development environment successfully!"

# Active redis in production environment
echo "⏳ Activating redis in production environment..."
# replace "# config.cache_store = :mem_cache_store" with config.cache_store = :redis_cache_store, { url: ENV.fetch('REDIS_URL', 'redis://localhost:6379/0') }
sed -i -e 's/# config.cache_store = :mem_cache_store/config.cache_store = :redis_cache_store, { url: ENV.fetch("REDIS_URL", "redis:\/\/localhost:6379\/0") }/g' config/environments/production.rb
rm config/environments/production.rb-e
echo "✅ Redis activated in production environment successfully!"

fi

# SIDEKIQ INSTALLATION
##

if [ "$SIDEKIQ_ACTIVATED" = true ]; then

# Add sidekiq gem to Gemfile and add it's dependencies
echo "⏳ Adding sidekiq gem to Gemfile and add it's dependencies..."
# add sidekiq gem
echo "
# Use sidekiq for background jobs
gem 'sidekiq'" >> Gemfile
# add sidekiq-scheduler gem
echo "
# Use sidekiq-scheduler for background jobs scheduling
gem 'sidekiq-scheduler'" >> Gemfile
# remove file Gemfile-e
rm Gemfile-e
echo "✅ sidekiq gem added to Gemfile and it's dependencies added successfully!"

# Activate sidekiq in development environment
echo "⏳ Activating sidekiq in development environment..."
# add "config.active_job.queue_adapter = :sidekiq" after "config.action_cable.disable_request_forgery_protection = true"
sed -i -e 's/config.action_cable.disable_request_forgery_protection = true/config.action_cable.disable_request_forgery_protection = true\n\n  # Use sidekiq for background jobs.\n  config.active_job.queue_adapter = :sidekiq/g' config/environments/development.rb
rm config/environments/development.rb-e
echo "✅ Sidekiq activated in development environment successfully!"

# Activate sidekiq in production environment
echo "⏳ Activating sidekiq in production environment..."
# replace "# config.active_job.queue_adapter     = :resque" with "config.active_job.queue_adapter = :sidekiq"
sed -i -e 's/# config.active_job.queue_adapter     = :resque/config.active_job.queue_adapter = :sidekiq/g' config/environments/production.rb
rm config/environments/production.rb-e
echo "✅ Sidekiq activated in production environment successfully!"

# Create a sidekiq.rb initializer to configure sidekiq
echo "⏳ Creating sidekiq.rb initializer..."
touch config/initializers/sidekiq.rb
echo "# Configure sidekiq to use redis as cache store

Sidekiq.configure_server do |config|
  config.redis = { url: ENV.fetch('REDIS_URL', 'redis://localhost:6379/0') }
end

Sidekiq.configure_client do |config|
  config.redis = { url: ENV.fetch('REDIS_URL', 'redis://localhost:6379/0') }
end
" > config/initializers/sidekiq.rb
echo "✅ sidekiq.rb initializer created successfully!"

# Add sidekiq web UI to routes file
echo "⏳ Adding sidekiq web UI to routes file..."
# add "require 'sidekiq/web'" on top of the file
sed -i -e 's/Rails.application.routes.draw do/require "sidekiq\/web"\n\nRails.application.routes.draw do/g' config/routes.rb
# add "mount Sidekiq::Web => '/sidekiq'" after "Rails.application.routes.draw do"
sed -i -e 's/Rails.application.routes.draw do/Rails.application.routes.draw do\n  mount Sidekiq::Web => "\/sidekiq"/g' config/routes.rb
rm config/routes.rb-e
echo "✅ Sidekiq web UI added to routes file successfully!"

# Create sidekiq.yml configuration file
echo "⏳ Creating sidekiq.yml configuration file..."
touch config/sidekiq.yml
echo "verbose: false
concurrency: 5
timeout: 30
max_retries: 3
pidfile: ./tmp/pids/sidekiq.pid
logfile: ./log/sidekiq.log

queues:
  - critical
  - default
  - mailers
  - low
  - action_mailbox_routing
  - action_mailbox_incineration
  - active_storage_analysis
  - active_storage_purge

# scheduler:
#   schedule:
#     ExampleJob:
#       cron: "*/1 * * * *"
#       class: "ExampleJob"
#       queue: "scheduled"
" > config/sidekiq.yml
echo "✅ sidekiq.yml configuration file created successfully!"

# Add sidekiq worker to Procfile
echo "⏳ Adding sidekiq worker to Procfile..."
echo "worker: bundle exec sidekiq -C config/sidekiq.yml -e \$RAILS_ENV" >> Procfile
echo "scheduler: IS_SCHEDULER=true bundle exec sidekiq -C config/sidekiq.yml -q scheduled -e \$RAILS_ENV" >> Procfile
echo "✅ Sidekiq worker added to Procfile successfully!"

fi

# FINAL STEPS
##

# Run bundle install
echo "⏳ Running bundle install..."
bundle install
echo "✅ bundle install completed successfully!"

# Install active storage
echo "⏳ Installing active storage..."
rails active_storage:install
echo "✅ active storage installed successfully!"

if [ "$LATO_ACTIVATED" = true ]; then

# Install lato
echo "⏳ Installing lato..."
rails lato:install:application
rails lato:install:migrations
echo "✅ lato installed successfully!"

fi

# Run installation tasks
echo "⏳ Running installation tasks..."
rails db:drop
rails db:create
rails db:migrate
rails db:seed
echo "✅ Installation tasks completed successfully!"

# Complete the rails app setup and print the success message
echo "🎉 $SERVICE_NAME service created successfully!"
echo "👨‍💻 You can start the app with 'rails s'"
