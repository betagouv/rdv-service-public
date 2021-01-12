test: ## Run the tests and rubocop
	bundle exec rubocop -A && bundle exec rspec --profile 3 && bundle exec brakeman

install: ## Install or update dependencies
	bundle install && yarn install && bundle exec rails db:migrate

run: ## Start the app server
	foreman s -f Procfile.dev

clean: ## Clean temporary files and installed dependencies
	bundle exec rails log:clear tmp:clear

