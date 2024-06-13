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
	RAILS_ENV=test bundle exec spring rake parallel:spec['spec\/(?!features)']

test_features:  ## Run feature tests
	bundle exec spring rspec spec/features

autocorrect: ## Fix autocorrectable lint issues
	bundle exec rubocop --auto-correct-all

clean: ## Clean temporary files (including weppacks) and logs
	bundle exec rails log:clear tmp:clear

generate_db_diagram: ## Generate docs/domain_model.svg from Rails models
	bundle exec erd

rswag: ## Re-generate swagger/v1/api.json by running API specs
	SWAGGER_DRY_RUN=0 RAILS_ENV=test rake rswag:specs:swaggerize PATTERN="spec/requests/api/**/*_spec.rb"

.PHONY: install run lint lint_rubocop lint_brakeman test test_unit test_features autocorrect clean generate_db_diagram help
.DEFAULT_GOAL := help

review_app: ## Create Scalingo review app for the PR linked to the current branch
	scalingo --region osc-secnum-fr1 --app demo-rdv-solidarites integration-link-manual-review-app `gh pr view --json number --jq '.number'`

help: ## Display available commands
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'
