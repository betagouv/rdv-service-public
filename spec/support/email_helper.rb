# frozen_string_literal: true

def email_sent_to(recipient)
  emails_sent_to(recipient).first
end

def emails_sent_to(recipient)
  ActionMailer::Base.deliveries.select { |email| [email.to, email.cc, email.bcc].flatten.compact.include?(recipient) }
end
