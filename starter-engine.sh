#! /bin/bash

# Ask the name of the rails engine to create
echo "👋 Welcome to the Rails Starter for Engines!"
echo "🤔 What's the name of the engine you want to create?"
read RAILS_ENGINE_NAME

# Ask if user want to activate lato
LATO_ACTIVATED=false
echo "🤔 Do you want to activate lato? (y/n)"
read ACTIVATE_LATO
if [ "$ACTIVATE_LATO" = "y" ]; then
  LATO_ACTIVATED=true
fi

# Create new rails engine using RAILS_ENGINE_NAME
echo "⏳ Creating new rails engine..."
rails plugin new $RAILS_ENGINE_NAME --mountable
echo "✅ New rails engine created successfully!"

# Change directory to RAILS_ENGINE_NAME
cd $RAILS_ENGINE_NAME

# Update rails engine gemspec to make it working
echo "⏳ Updating rails engine gemspec..."
sed -i '' -e 's/TODO: //g' $RAILS_ENGINE_NAME.gemspec
sed -i '' -e 's/spec.homepage    = "TODO"/spec.homepage    = "https:\/\/mysite.com"/g' $RAILS_ENGINE_NAME.gemspec
sed -i '' -e 's/spec.metadata\["allowed_push_host"\]/# spec.metadata\["allowed_push_host"\]/g' $RAILS_ENGINE_NAME.gemspec
sed -i '' -e 's/spec.metadata\["source_code_uri"\]/# spec.metadata\["source_code_uri"\]/g' $RAILS_ENGINE_NAME.gemspec
sed -i '' -e 's/spec.metadata\["changelog_uri"\]/# spec.metadata\["changelog_uri"\]/g' $RAILS_ENGINE_NAME.gemspec
echo "✅ Rails engine gemspec updated successfully!"

# Create javascript file for the engine
echo "⏳ Creating javascript file for the engine..."
mkdir app/assets/javascripts
mkdir app/assets/javascripts/$RAILS_ENGINE_NAME
touch app/assets/javascripts/$RAILS_ENGINE_NAME/application.js
echo "✅ Created javascript file for the engine!"

# Added link to javascript assets on manifest
echo "⏳ Added link to javascript assets on manifest..."
echo "
//= link_directory ../images/$RAILS_ENGINE_NAME .jpg
//= link_tree ../javascripts/$RAILS_ENGINE_NAME .js" >> app/assets/config/${RAILS_ENGINE_NAME}_manifest.js

if [ "$LATO_ACTIVATED" = true ]; then

# Add lato to rails engine gemspec
echo "⏳ Adding lato to rails engine gemspec..."
sed -i '' -e '$i\
  spec.add_dependency "lato"
' $RAILS_ENGINE_NAME.gemspec
echo "✅ Lato added to rails engine gemspec successfully!"

# Add lato dependencies to rails engine Gemfile
echo "⏳ Adding lato dependencies to rails engine Gemfile..."
echo "
# Lato dependencies
gem 'importmap-rails'
gem 'turbo-rails'
gem 'stimulus-rails'
gem 'sassc-rails'
gem 'bootstrap'
gem 'lato'
" >> Gemfile
echo "✅ Lato dependencies added to rails engine Gemfile successfully!"

# Change directory to test/dummy
cd test/dummy

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
mkdir app/javascript
touch app/javascript/application.js
echo "import \"lato/application\";" >> app/javascript/application.js
echo "✅ lato javascript imported in application.js successfully!"

# Create importmap.rb file in config
echo "⏳ Creating importmap.rb file in config..."
touch config/importmap.rb
echo "
# Pin npm packages by running ./bin/importmap

pin \"application\"
pin_all_from \"app/javascript/controllers\", under: \"controllers\"

pin \"@hotwired/turbo-rails\", to: \"turbo.min.js\", preload: true
pin \"@hotwired/stimulus\", to: \"stimulus.min.js\", preload: true
pin \"@hotwired/stimulus-loading\", to: \"stimulus-loading.js\", preload: true" >> config/importmap.rb
echo "✅ Importmap file created successfully!"

# Add link to javascript assets on manifest
echo "⏳ Add link to javascript assets on manifest..."
echo "
//= link_tree ../../javascript .js" >> app/assets/config/manifest.js
echo "✅ Added link to javascript assets on manifest!"

# Edit routes file to mount lato engine
echo "⏳ Editing routes file to mount lato engine..."
sed -i -e 's/Rails.application.routes.draw do/Rails.application.routes.draw do\n  mount Lato::Engine => "\/adm"/g' config/routes.rb
rm config/routes.rb-e
echo "✅ Routes file edited successfully!"

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
echo "✅ Seeds file edited successfully!"

# Install active storage
echo "⏳ Installing active storage..."
rails active_storage:install
echo "✅ Active storage installed successfully!"

# Install lato
echo "⏳ Installing lato..."
rails lato:install:application
rails lato:install:migrations
echo "✅ Lato installed successfully!"

# Go back to the root directory
cd ../..

fi

# Run installation tasks
echo "⏳ Running installation tasks..."
rails db:drop
rails db:create
rails db:migrate
rails db:seed
echo "✅ Installation tasks completed successfully!"

# Complete the rails engine setup and print the success message
echo "🎉 $RAILS_ENGINE_NAME rails engine created successfully!"
echo "👨‍💻 You can start the develop"
