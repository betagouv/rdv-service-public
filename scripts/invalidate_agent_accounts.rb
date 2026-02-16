# Usage: bundle exec rails runner scripts/invalidate_agent_accounts.rb agent1@domain.fr agent2@domain.fr ...
# invalide le mot de passe des agents et déconnecte les sessions existantes

emails = ARGV.map(&:downcase).uniq
emails.each do |email|
  puts "Invalidating account for #{email}..."
  agent = Agent.find_by(email:)
  PaperTrail.request.whodunnit = "invalidate_agent_accounts_script"
  agent.encrypted_password = ""
  agent.paper_trail.save_with_version
  raise unless agent.reload.encrypted_password == "" # il n'y a pas de save_with_version!

  puts "Invalidated account for #{email}."
end
