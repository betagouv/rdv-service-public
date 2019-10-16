class DeviseMailerPreview < ActionMailer::Preview
  def confirmation_instructions
    Devise::Mailer.confirmation_instructions(Agent.first, {})
  end

  def reset_password_instructions
    Devise::Mailer.reset_password_instructions(Agent.first, "faketoken")
  end
end
