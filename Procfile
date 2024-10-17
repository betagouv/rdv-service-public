web: ./bin/start_web_server
jobs: bundle exec good_job start
postdeploy: bundle exec rake bundle exec rake db:schema:load db:seed
