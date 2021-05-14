# frozen_string_literal: true

class CustomDeviseMailerPreview < ActionMailer::Preview
  def confirmation_instructions
    CustomDeviseMailer.confirmation_instructions(Agent.first, {})
  end

  def reset_password_instructions
    CustomDeviseMailer.reset_password_instructions(Agent.first, "faketoken")
  end

  def invitation_instructions_for_agents
    CustomDeviseMailer.invitation_instructions(Agent.last, "faketoken")
  end

  def invitation_instructions
    CustomDeviseMailer.invitation_instructions(User.last, "faketoken")
  end
end
