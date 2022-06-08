# frozen_string_literal: true

class Agents::ReplyTransferMailerPreview < ActionMailer::Preview
  def notify_agent_of_user_reply
    rdv = Rdv.last

    source_mail = Mail.new do
      subject "Re: RDV confirmé le #{I18n.l(rdv.starts_at, format: :human)}"

      text_part do
        body "Bonjour,\nVoici une phrase après un saut de ligne."
      end

      attachments["signature.svg"] = { mime_type: "image/svg+xml", content: "" }
    end

    body = <<~MARKDOWN
      Bonjour,
      Voici une phrase après un saut de ligne.

      Voici une autre phrase après deux sauts de ligne (saut de paragraphe)
    MARKDOWN

    Agents::ReplyTransferMailer.notify_agent_of_user_reply(
      rdv: rdv,
      author: rdv.users.first,
      agents: rdv.agents,
      reply_body: body,
      source_mail: source_mail
    )
  end
end
