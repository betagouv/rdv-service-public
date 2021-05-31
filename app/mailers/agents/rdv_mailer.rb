# frozen_string_literal: true

class Agents::RdvMailer < ApplicationMailer
  include DateHelper
  add_template_helper DateHelper

  def rdv_created(rdv, agent)
    @rdv = rdv
    @agent = agent

    with_ics_for(@rdv) do
      mail(to: agent.email, subject: "Nouveau RDV ajouté sur votre agenda rdv-solidarités pour #{relative_date @rdv.starts_at}")
    end
  end

  def rdv_cancelled(rdv, agent, author)
    @rdv = rdv
    @agent = agent
    @author = author

    with_ics_for(@rdv) do
      mail(to: agent.email, subject: "RDV annulé #{relative_date @rdv.starts_at}")
    end
  end

  def rdv_date_updated(rdv, agent, author, old_starts_at)
    @rdv = rdv
    @agent = agent
    @author = author
    @old_starts_at = old_starts_at

    with_ics_for(@rdv) do
      mail(to: agent.email, subject: "RDV #{relative_date old_starts_at} reporté à plus tard")
    end
  end

  def with_ics_for(rdv, &block)
    ics_payload = Admin::Ics::Rdv.payload(rdv, rdv.users.first)
    ics = Admin::Ics::Rdv.to_ical(ics_payload)
    message.attachments[ics_payload[:name]] = { # as an attachment
      mime_type: "text/calendar",
      content: ics,
      encoding: "8bit" # not sure why
    }

    message = yield block

    message.add_part( # and as a separate part
      Mail::Part.new do
        content_type "text/calendar; charset=utf-8"
        body Base64.encode64(ics)
        content_transfer_encoding "base64"
      end
    )

    message
  end
end
