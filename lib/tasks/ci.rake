task :ci do
  sh "bundle exec rspec"
  sh "bundle exec brakeman --no-pager"
  sh "bundle exec rubocop"
end
