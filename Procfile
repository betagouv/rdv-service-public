web: ./bin/start_web_server
jobs: bundle exec bin/delayed_job run
postdeploy: bundle exec rake db:migrate && SWAGGER_DRY_RUN=0 RAILS_ENV=test rails rswag:specs:swaggerize
