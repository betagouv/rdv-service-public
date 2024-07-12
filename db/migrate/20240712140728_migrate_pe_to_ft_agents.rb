class MigratePeToFtAgents < ActiveRecord::Migration[7.0]
  def change
    # Step 1: Identify email prefixes for pole-emploi.fr domain
    pole_emploi_emails = Agent.where("email LIKE ?", "%@pole-emploi.fr").pluck(:email).map { |email| email.split("@").first }
    # Step 2: Identify email prefixes for francetravail.fr domain
    france_travail_emails = Agent.where("email LIKE ?", "%@francetravail.fr").pluck(:email).map { |email| email.split("@").first }
    # Step 3: Find common email prefixes (these are potential duplicates)
    common_email_prefixes = pole_emploi_emails & france_travail_emails
    # Step 4: Find agents with duplicate email prefixes 0 agent at 12/07/2024
    duplicated_agents = Agent.where("split_part(email, '@', 1) IN (?)", common_email_prefixes)
    # Step 5: Exclude duplicated agents from the email update
    duplicated_agent_ids = duplicated_agents.pluck(:id)

    # Step 6: Update the remaining agents' emails with callbacks (important for Webhooks) but without Devise reconfirmation
    # We will send a separate email to these agents to inform them of the change
    Agent.transaction do
      Agent.where("email LIKE ?", "%@pole-emploi.fr")
        .where.not(id: duplicated_agent_ids)
        .find_each(batch_size: 100) do |agent|
        # Temporarily skip Devise reconfirmation
        agent.skip_reconfirmation!
        agent.email = agent.email.gsub("@pole-emploi.fr", "@francetravail.fr")
        agent.save!
      end
    end
  end
end
