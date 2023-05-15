web: ./bin/start_web_server
jobs: bundle exec good_job start
postdeploy: bundle exec rails db:create db:schema:load
