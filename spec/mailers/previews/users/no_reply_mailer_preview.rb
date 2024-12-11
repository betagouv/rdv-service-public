class Users::NoReplyMailerPreview < ActionMailer::Preview
  def no_reply
    source_mail = Mail.new do
      from "jeanne@barret.fr"
      to "ne-pas-repondre@reply.rdv-solidarites-test.localhost"
    end

    Users::NoReplyMailer.with(source_mail:).no_reply
  end
end
