#! /bin/bash

# Ask name of the service to user
echo "Enter the name of the service: "
read service_name
echo "Service name is: $service_name"

# Install Docked [https://github.com/rails/docked]
# NOTE: Docked is a tool for managing Docker Compose-based development environments for Rails.
echo "⏳ Installing Docked..."
docker volume create ruby-bundle-cache
alias docked='docker run --rm -it -v ${PWD}:/rails -v ruby-bundle-cache:/bundle -p 3000:3000 ghcr.io/rails/cli'
echo "✅ Docked installed successfully!"

# Create new rails app using service name
echo "⏳ Creating new rails app..."
docked rails new $service_name
echo "✅ New rails app created successfully!"

# Change directory to service name
cd $service_name

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
      POSTGRES_DB: $service_name
    ports:
      - 5432:5432
  redis:
    image: redis:6.2-alpine
    volumes:
      - redis:/data
    ports:
      - 6379:6379
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

# Install dependencies
RUN apt-get update -qq && apt-get install -y build-essential libvips gnupg2 curl git

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

# Add gem lato to Gemfile
echo "⏳ Adding gem lato to Gemfile..."
echo "
# Create custom web ui using lato gem [https://github.com/lato-gam/lato]
gem 'lato'" >> Gemfile
echo "✅ Gem lato added successfully!"

# TODO: Continue lato installation..

# Complete the rails app setup and print the success message
echo "🎉 $service_name service created successfully!"
echo ""
echo "🎉 To run the service, run the following command:"
echo "$ docker-compose up"
echo ""
echo "🎉 To run rails console, run the following command:"
echo "$ docker-compose run web rails c"
echo ""
echo "🎉 To run rails tasks, run  the following command:"
echo "$ docker-compose run web rails TASK_NAME"
echo ""