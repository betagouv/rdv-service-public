require "shellwords"

pr_number = `gh pr view --json number --jq '.number'`.strip
exit(1) if $?.exitstatus != 0 # On quitte si aucune PR n'est liée à la branche courante

pr_body = `gh pr view --json body --jq '.body'`
review_app_name = "rdv-service-public-review-app-pr#{pr_number}"
review_app_url = "https://#{review_app_name}.osc-secnum-fr1.scalingo.io/"

if pr_body.include?(review_app_url)
  puts "La description de PR contient déjà un lien vers la review app."
  exit(0)
end

review_app_exists = system("scalingo --app #{review_app_name} stats", out: IO::NULL, err: IO::NULL)
unless review_app_exists
  puts "La review app n'existe pas encore, création en cours..."
  system("scalingo --region osc-secnum-fr1 --app rdv-service-public-review-app integration-link-manual-review-app #{pr_number}")
end

link_to_review_app = "[Review app](#{review_app_url})"
new_body = "#{link_to_review_app}\n\n#{pr_body}"
system("gh pr edit -b #{Shellwords.escape(new_body)}", out: IO::NULL, err: IO::NULL)
puts "Lien ajouté à la description de PR : #{link_to_review_app}"

exit(0)
