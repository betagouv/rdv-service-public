# frozen_string_literal: true

class Agents::RdvMailer < ApplicationMailer
  include DateHelper
  add_template_helper DateHelper

  def rdv_created(rdv_payload, agent)
    @rdv = OpenStruct.new(rdv_payload)
    @agent = agent

    self.ics_payload = @rdv

    mail(to: agent.email, subject: "Nouveau RDV ajouté sur votre agenda rdv-solidarités pour #{relative_date @rdv.starts_at}")
  end

  def rdv_cancelled(rdv_payload, agent, author)
    @rdv = OpenStruct.new(rdv_payload)
    @agent = agent
    @author = author

    self.ics_payload = @rdv

    mail(to: agent.email, subject: "RDV annulé #{relative_date @rdv.starts_at}")
  end

  def rdv_date_updated(rdv_payload, agent, author, old_starts_at)
    @rdv = OpenStruct.new(rdv_payload)
    @agent = agent
    @author = author
    @old_starts_at = old_starts_at

    self.ics_payload = @rdv

    mail(to: agent.email, subject: "RDV #{relative_date old_starts_at} reporté à plus tard")
  end
end
