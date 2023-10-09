# frozen_string_literal: true

class TransferEmailReplyJob < ApplicationJob
  queue_as :mailers

  # Pour éviter de fuiter des données personnelles dans les logs
  self.log_arguments = false

  def self.reply_address_for_rdv(rdv)
    "rdv+#{rdv.uuid}@reply.rdv-solidarites.fr"
  end

  UUID_EXTRACTOR = /rdv\+([a-f0-9\-]*)@reply\.rdv-solidarites\.fr/

  def perform(sendinblue_hash)
    @sendinblue_hash = sendinblue_hash.with_indifferent_access

    if rdv
      notify_agents
    else
      forward_to_default_mailbox
    end
  end

  private

  def notify_agents
    Agents::ReplyTransferMailer.notify_agent_of_user_reply(
      rdv: rdv,
      author: user || source_mail.header[:from],
      agents: rdv.agents,
      reply_body: extracted_response,
      source_mail: source_mail
    ).deliver_now
  end

  def forward_to_default_mailbox
    Agents::ReplyTransferMailer.forward_to_default_mailbox(
      reply_body: extracted_response,
      source_mail: source_mail
    ).deliver_now
  end

  def rdv
    Rdv.find_by(uuid: uuid) if uuid
  end

  def user
    rdv&.users&.find_by(email: source_mail.from.first)
  end

  def uuid
    source_mail.to.first.match(UUID_EXTRACTOR)&.captures&.first
  end

  def extracted_response
    # Sendinblue provides us with both
    #   - the RAW email body (text + HTML)
    #   - a smart extraction of the content in markdown format
    # We chose to use the smart extract because it already does all
    # the hard work of excluding the quoted reply part.
    [@sendinblue_hash[:ExtractedMarkdownMessage], @sendinblue_hash[:ExtractedMarkdownSignature]].compact.join("\n\n")
  end

  # @return [Mail::Message]
  def source_mail
    payload = @sendinblue_hash

    @source_mail ||= Mail.new do
      headers payload[:Headers]
      subject payload[:Subject]

      if payload[:RawTextBody].present?
        text_part do
          body payload[:RawTextBody]
        end
      end

      if payload[:RawHtmlBody].present?
        html_part do
          content_type "text/html; charset=UTF-8"
          body payload[:RawHtmlBody]
        end
      end

      payload.fetch(:Attachments, []).each do |attachment_payload|
        attachments[attachment_payload[:Name]] = {
          mime_type: attachment_payload[:ContentType],
          content: "", # Sendinblue webhook does not provide the content of attachments
        }
      end
    end
  end
end
