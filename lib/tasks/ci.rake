task :ci do
  sh 'bundle exec brakeman --no-pager'
  sh 'bundle exec rubocop'
end
