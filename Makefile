install: ## Install project & dependencies
	bundle install && yarn install && bundle exec rails db:migrate

update: ## update project & dependencies
	git pull --rebase --prune https://github.com/betagouv/rdv-solidarites.fr.git master && bundle install && yarn install && bundle exec rails db:migrate

test: ## Run the tests and rubocop
	bundle exec rubocop -a && bundle exec rspec --profile 3 && bundle exec brakeman

run: ## Start the app server
	foreman s -f Procfile.dev

stop: ## Stop the app server
	foreman stop

clean: ## Clean temporary files and installed dependencies
	bundle exec rails log:clear tmp:clear

