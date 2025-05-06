class CustomDeviseMailerPreview < ActionMailer::Preview
  def confirmation_instructions_signup
    agent = Agent.new(
      email: "ancien_email@demo.rdv-insertion.fr",
      confirmed_at: nil,
      confirmation_token: "abcd1234"
    )
    agent.readonly!
    CustomDeviseMailer.confirmation_instructions(agent, agent.confirmation_token)
  end

  def confirmation_instructions_email_update
    agent = Agent.new(
      email: "ancien_email@demo.rdv-insertion.fr",
      confirmed_at: 2.days.ago,
      unconfirmed_email: "alain-nouveau@demo.rdv-insertion.fr",
      confirmation_token: "abcd1234"
    )
    agent.readonly!
    CustomDeviseMailer.confirmation_instructions(agent, agent.confirmation_token)
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
