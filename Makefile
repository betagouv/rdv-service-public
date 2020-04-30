deploy:
	bundle exec ruby ./scripts/deploy.rb

test: ## Run the tests and rubocop
	bundle exec rubocop -a && bundle exec rspec --profile 3

install: ## Install or update dependencies
	bundle install && yarn install && bundle exec rails db:migrate

run: ## Start the app server
	foreman s -f Procfile.dev

stop: ## Stop the app server
	foreman stop

clean: ## Clean temporary files and installed dependencies
	bundle exec rails log:clean tmp:clean

.PHONY: deploy install run test clean stop
