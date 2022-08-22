# frozen_string_literal: true

class Agents::ReplyTransferMailer < ApplicationMailer
  include DateHelper
  include ActionView::Helpers::TextHelper

  # @param [Rdv] rdv
  # @param [User, String] author
  # @param [Array<Agent>] agents
  # @param [Mail::Message] source_mail
  def notify_agent_of_user_reply(rdv:, author:, agents:, reply_body:, source_mail:)
    @rdv = rdv
    @author = author
    @reply_subject = source_mail.subject
    @reply_body = reply_body
    @attachment_names = source_mail.attachments.map(&:filename).join(", ")
    @date = relative_date(@rdv.starts_at)

    mail(to: agents.map(&:email), subject: t(".title", date: @date))
  end

  # @param [String] reply_body
  # @param [Mail::Message] source_mail
  def forward_to_default_mailbox(reply_body:, source_mail:)
    @author = source_mail.header[:from]
    @reply_subject = source_mail.subject
    @reply_body = reply_body
    @attachment_names = source_mail.attachments.map(&:filename).join(", ")

    mail(to: SUPPORT_EMAIL, subject: t(".title"))
  end

  private

  def domain
    @rdv&.domain || Domain::RDV_SOLIDARITES
  end
end
