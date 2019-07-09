task :ci do
  sh "bin/rspec"
  sh "bundle exec brakeman --no-pager"
  sh "bundle exec rubocop"
end
