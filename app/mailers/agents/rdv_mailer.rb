# frozen_string_literal: true

class Agents::RdvMailer < ApplicationMailer
  include DateHelper
  add_template_helper DateHelper

  def rdv_starting_soon_created(rdv, agent)
    @rdv = rdv
    @agent = agent

    mail(
      to: agent.email,
      subject: "Nouveau RDV ajouté sur votre agenda rdv-solidarités pour #{relative_date @rdv.starts_at}"
    )
  end

  def rdv_starting_soon_cancelled(rdv, agent, cancelled_by_str)
    @rdv = rdv
    @agent = agent
    @cancelled_by_str = cancelled_by_str

    mail(to: agent.email, subject: "RDV annulé #{relative_date @rdv.starts_at}")
  end

  def rdv_starting_soon_date_updated(rdv, agent, rdv_updated_by_str)
    old_starts_at = rdv.attribute_before_last_save(:starts_at)
    @rdv = rdv
    @agent = agent
    @rdv_updated_by_str = rdv_updated_by_str
    @old_starts_at = old_starts_at

    mail(to: agent.email, subject: "RDV #{relative_date old_starts_at} reporté à plus tard")
  end
end
