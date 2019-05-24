module Devise
  class MailerPreview < ActionMailer::Preview
    def confirmation_instructions
      Devise::Mailer.confirmation_instructions(Pro.first, {})
    end

    def reset_password_instructions
      Devise::Mailer.reset_password_instructions(Pro.first, "faketoken")
    end
  end
end
