#! /bin/bash

# Read service name from first argument
SERVICE_NAME=$1

# Install Docked [https://github.com/rails/docked]
# NOTE: Docked is a tool for managing Docker Compose-based development environments for Rails.
echo "⏳ Installing Docked..."
docker volume create ruby-bundle-cache
alias docked='docker run --rm -it -v ${PWD}:/rails -v ruby-bundle-cache:/bundle -p 3000:3000 ghcr.io/rails/cli'
echo "✅ Docked installed successfully!"

# Create new rails app using service name
echo "⏳ Creating new rails app..."
docked rails new $SERVICE_NAME
echo "✅ New rails app created successfully!"

# Change directory to service name
cd $SERVICE_NAME

# Create a docker-compose.yml file for the service with postgresql, redis and rails
echo "⏳ Creating docker-compose.yml file..."
echo "version: '3.8'
services:
  db:
    image: postgres:13.2-alpine
    volumes:
      - postgres:/var/lib/postgresql/data
    environment:
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgres
      POSTGRES_DB: $SERVICE_NAME
    ports:
      - 5432:5432
  redis:
    image: redis:6.2-alpine
    volumes:
      - redis:/data
    ports:
      - 6379:6379
  pgadmin:
    image: dpage/pgadmin4
    environment:
      PGADMIN_DEFAULT_EMAIL: admin@mail.com
      PGADMIN_DEFAULT_PASSWORD: Password1!
    volumes:
      - ./pgadmin:/var/lib/pgadmin
    ports:
      - 5050:80
    depends_on:
      - db
  web:
    build: .
    command: bundle exec rails s -p 3000 -b 0.0.0.0
    volumes:
      - .:/rails
      - ruby-bundle-cache:/bundle
    ports:
      - 3000:3000
    depends_on:
      - db
      - redis
volumes:
  postgres:
  redis:
  ruby-bundle-cache:" > docker-compose.yml
echo "✅ docker-compose.yml file created successfully!"

# Create a Dockerfile for the service
echo "⏳ Creating Dockerfile..."
echo "FROM ruby:3.2.0-slim

# Install general dependencies
RUN apt-get update -qq && apt-get install -y build-essential libvips gnupg2 curl git

# Install node and yarn dependencies
RUN curl -sL https://deb.nodesource.com/setup_18.x | bash -
RUN apt-get update -qq && apt-get install -y nodejs && npm install -g yarn

# Install postgresql dependencies
RUN apt-get update -qq && apt-get install -y libpq-dev

# Mount the Rails application
WORKDIR /rails
COPY . ./

# Install bundler
RUN gem install bundler

# Install gems
RUN bundle install

# Start the main process
CMD bundle exec rails s -p 3000 -b 0.0.0.0
EXPOSE 3000
" > Dockerfile
echo "✅ Dockerfile created successfully!"

# Edit Gemfile
echo "⏳ Editing Gemfile..."
# add lato gem
echo "
# Create custom web ui using lato gem [https://github.com/lato-gam/lato]
gem 'lato'" >> Gemfile
# add pg gem
echo "
# Use postgresql as the database for Active Record
gem 'pg'" >> Gemfile
# add version 1.3.3 to turbo-rails gem
sed -i -e 's/gem "turbo-rails"/gem "turbo-rails", "1.3.3"/g' Gemfile
# uncomment the kredis gem
sed -i -e 's/# gem "kredis"/gem "kredis"/g' Gemfile
# uncomment the sassc-rails gem
sed -i -e 's/# gem "sassc-rails"/gem "sassc-rails"/g' Gemfile
# remove file Gemfile-e
rm Gemfile-e
echo "✅ Gemfile edited successfully!"

# Build the docker image
echo "⏳ Building the docker image..."
docker-compose build
echo "✅ Docker image built successfully!"

# Install gems
echo "⏳ Installing gems..."
docker-compose run web bundle install
echo "✅ Gems installed successfully!"

# Install  kredis
echo "⏳ Installing kredis..."
docker-compose run web rails kredis:install
echo "✅ kredis installed successfully!"

# Install active storage
echo "⏳ Installing active storage..."
docker-compose run web rails active_storage:install
echo "✅ active storage installed successfully!"

# Install lato
echo "⏳ Installing lato..."
docker-compose run web rails lato:install:application
docker-compose run web rails lato:install:migrations
echo "✅ lato installed successfully!"

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

# Configure I18n in application.rb
echo "⏳ Configuring I18n in application.rb..."
# set default locale to en (add line after config.load_defaults 7.0)
sed -i -e 's/config.load_defaults 7.0/config.load_defaults 7.0\n    config.i18n.default_locale = :en/g' config/application.rb
# set available locales to en and it (add line after config.i18n.default_locale = :en)
sed -i -e 's/config.i18n.default_locale = :en/config.i18n.default_locale = :en\n    config.i18n.available_locales = [:en, :it]/g' config/application.rb
rm config/application.rb-e
echo "✅ I18n configured in application.rb successfully!"

# Edit routes file to mount lato engine
echo "⏳ Editing routes file to mount lato engine..."
sed -i -e 's/Rails.application.routes.draw do/Rails.application.routes.draw do\n  mount Lato::Engine => "\/adm"/g' config/routes.rb
rm config/routes.rb-e
echo "✅ Routes file edited successfully!"

# Edit seeds file to create a default admin user
echo "⏳ Editing seeds file to create a default admin user..."
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
puts 'Default admin user created successfully!'" >> db/seeds.rb

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

# Edit database.yml file to use postgresql in development and production environments
echo "⏳ Editing database.yml file to use postgresql in development and production environments..."
rm config/database.yml
touch config/database.yml
echo "default: &default
  adapter: sqlite3
  pool: 5
  timeout: 5000

test:
  <<: *default
  database: db/test.sqlite3

development:
  <<: *default
  adapter: postgresql
  database: $SERVICE_NAME
  username: postgres
  password: postgres
  host: db
  port: 5432

production:
  <<: *default
  adapter: postgresql
  database: $SERVICE_NAME
  username: postgres
  password: postgres
  host: db
  port: 5432" >> config/database.yml
echo "✅ database.yml file edited successfully!"

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

# Run installation tasks
echo "⏳ Running installation tasks..."
docker-compose run web rails db:create
docker-compose run web rails db:migrate
docker-compose run web rails db:seed
echo "✅ Installation tasks completed successfully!"

# Create a custom README.md file
echo "⏳ Creating README.md file..."
echo "# $SERVICE_NAME

## Description

This is a [Rails](https://rubyonrails.org/) application dockerized.
The default database is postgresql.
The default cache store is redis.

All required services are configured in the docker-compose.yml file.

## Getting Started

### Prerequisites

- [Docker](https://docs.docker.com/get-docker/)
- [Docker Compose](https://docs.docker.com/compose/install/)

### Installation

1. Clone the repo with **git clone**

2. Build the docker image with **docker-compose build**

3. Create the database with **docker-compose run web rails db:create**

4. Run the migrations with **docker-compose run web rails db:migrate**

5. Run seed data with **docker-compose run web rails db:seed**

### Usage

- Start the app with **docker-compose up**

- Run rails console with **docker-compose run web rails c**

- Run rails tasks with **docker-compose run web rails TASK_NAME**

- Run tests with **docker-compose run web rails test**

The homepage of the app will be available at [http://localhost:3000](http://localhost:3000)
The admin panel of the app will be available at [http://localhost:3000/adm](http://localhost:3000/adm)
The pgadmin panel of the app will be available at [http://localhost:5050](http://localhost:5050)

You can login in the admin panel with the following credentials:
- email: admin@mail.com
- password: Password1!

You can login in the pgadmin panel with the following credentials:
- email: admin@mail.com
- password: Password1!

### Connect to the database from pgadmin

1. Open pgadmin panel at [http://localhost:5050](http://localhost:5050)
2. Create a new server
3. Set the following credentials:
- host: db
- port: 5432
- username: postgres
- password: postgres
4. Click on save

### Connect to the database from local SQL client

1. Host: localhost
2. Port: 5432
3. Username: postgres
4. Password: postgres

" > README.md
echo "✅ README.md file created successfully!"

# Complete the rails app setup and print the success message
echo "🎉 $SERVICE_NAME service created successfully!"
echo "👨‍💻 You can start the app with 'docker-compose up'"
