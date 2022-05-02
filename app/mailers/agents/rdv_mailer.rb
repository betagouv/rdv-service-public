# frozen_string_literal: true

class Agents::RdvMailer < ApplicationMailer
  include DateHelper
  helper DateHelper

  def rdv_created(rdv, agent)
    @rdv = rdv
    @agent = agent

    self.ics_payload = @rdv.payload(:create, agent)

    mail(to: agent.email, subject: "Nouveau RDV ajouté sur votre agenda rdv-solidarités pour #{relative_date @rdv.starts_at}")
  end

  def rdv_cancelled(rdv, agent, author)
    @rdv = rdv
    @agent = agent
    @author = author

    self.ics_payload = @rdv.payload(:destroy, agent)

    mail(to: agent.email, subject: "RDV annulé #{relative_date @rdv.starts_at}")
  end

  def rdv_date_updated(rdv, agent, author, old_starts_at)
    @rdv = rdv
    @agent = agent
    @author = author
    @old_starts_at = old_starts_at

    self.ics_payload = @rdv.payload(:update, agent)

    mail(to: agent.email, subject: "RDV #{relative_date old_starts_at} reporté à plus tard")
  end
end
