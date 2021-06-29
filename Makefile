install: ## Setup development environment
	bin/setup

run: ## Start the application (web, jobs et webpack)
	foreman s -f Procfile.dev

lint: lint_rubocop lint_slim lint_brakeman ## Run all linters

lint_rubocop: ## Ruby linter
	bundle exec rubocop --parallel

lint_slim: ## Slim Linter
	bundle exec slim-lint app/views/

lint_brakeman: ## Security Checker
	bundle exec brakeman --no-pager

test: test_unit test_features ## Run all tests

test_unit:  ## Run unit tests in parallel
	RAILS_ENV=test bundle exec rake parallel:spec['spec\/(?!features)']

test_features:  ## Run feature tests
	bundle exec rspec spec/features

autocorrect: ## Fix autocorrectable lint issues
	bundle exec rubocop --auto-correct-all

clean: ## Clean temporary files (including weppacks) and logs
	bundle exec rails log:clear tmp:clear

help: ## Display available commands
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

.PHONY: install run lint test autocorrect clean help
.DEFAULT_GOAL := help
