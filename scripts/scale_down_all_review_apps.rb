# frozen_string_literal: true

# ruby ./scripts/scale_down_all_review_apps.rb

res = `scalingo apps` # backticks run shell commands
res.scan(/demo-rdv-solidarites-pr(\d+)/).each do |matches|
  pr_number = matches.first
  puts "./scripts/scale_review_app.sh #{pr_number} down"
  system("./scripts/scale_review_app.sh #{pr_number} down")
end
