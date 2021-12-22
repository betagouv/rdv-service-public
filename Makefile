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

recette_log: ## Deployment: List merged changes, ready to deploy
	git log --merges production..recette --oneline --no-decorate

recette_pull_all:
	git checkout recette && git pull origin recette:recette --ff-only
	git checkout production && git pull origin production:production --ff-only

recette_rebase_onto_production: ## Deployment: Rebase the recette branch and its merge commits onto the production branch.
	git checkout recette && git rebase --rebase-merges production

recette_merge_in_production:    ## Deployment: Fast-forward the production branch to the recette branch
	git checkout recette && git tag `date +%Y-%m-%d-%H-%M-%s`-deploy-recette-to-production
	git checkout production && git merge recette --ff-only

recette_deploy_to_production: recette_pull_all recette_rebase_onto_production recette_merge_in_production ## Deploy the current status of recette to production
	git checkout production && git push origin production --tags

clean: ## Clean temporary files (including weppacks) and logs
	bundle exec rails log:clear tmp:clear

help: ## Display available commands
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

.PHONY: install run lint lint_rubocop lint_brakeman test test_unit test_features autocorrect rebase_recette clean help
.DEFAULT_GOAL := help
