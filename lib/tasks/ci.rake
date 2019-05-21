task :ci do
  sh "bundle exec rails test"
  sh "bundle exec brakeman --no-pager"
end
