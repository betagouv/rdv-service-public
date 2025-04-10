class CustomDeviseMailerPreview < ActionMailer::Preview
  def confirmation_instructions
    agent = Agent.first
    agent.readonly!
    agent.unconfirmed_email = "alain-nouveau@rdv-insertion.fr"
    CustomDeviseMailer.confirmation_instructions(agent, {})
  end

  def reset_password_instructions
    CustomDeviseMailer.reset_password_instructions(Agent.first, "faketoken")
  end

  def invitation_instructions_for_agents
    CustomDeviseMailer.invitation_instructions(Agent.last, "faketoken")
  end

  def invitation_instructions_cnfs
    CustomDeviseMailer.invitation_instructions(Agent.joins(:services).where(services: { name: Service::CONSEILLER_NUMERIQUE }, invited_by: nil).last, "faketoken")
  end

  def invitation_instructions
    CustomDeviseMailer.invitation_instructions(User.where.not(invitation_sent_at: nil).last, "faketoken")
  end
end
