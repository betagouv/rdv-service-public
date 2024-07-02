web: ./bin/start_web_server
jobs: bundle exec good_job start
postdeploy: bundle exec rake db:migrate
web_maintenance: bundle exec ruby maintenance.rb