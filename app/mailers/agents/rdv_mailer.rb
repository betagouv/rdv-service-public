# frozen_string_literal: true

class Agents::RdvMailer < ApplicationMailer
  def rdv_starting_soon_created(rdv, agent)
    @rdv = rdv
    @agent = agent
    @date_str = date_to_string(@rdv.starts_at.to_date)
    mail(
      to: agent.email,
      subject: "Nouveau RDV ajouté sur votre agenda rdv-solidarités pour #{@date_str}"
    )
  end

  def rdv_starting_soon_cancelled(rdv, agent, cancelled_by_str)
    @rdv = rdv
    @agent = agent
    @cancelled_by_str = cancelled_by_str
    @date_str = date_to_string(@rdv.starts_at.to_date)
    mail(to: agent.email, subject: "RDV annulé #{@date_str}")
  end

  def rdv_starting_soon_date_updated(rdv, agent, rdv_updated_by_str, rdv_starts_at_before_update)
    @rdv = rdv
    @agent = agent
    @rdv_updated_by_str = rdv_updated_by_str
    @rdv_starts_at_before_update_date_str = date_to_string(rdv_starts_at_before_update.to_date)
    @rdv_starts_at_before_update = rdv_starts_at_before_update
    mail(to: agent.email, subject: "RDV #{@rdv_starts_at_before_update_date_str} reporté à plus tard")
  end

  private

  def date_to_string(date)
    # TODO: should be a helper
    { Date.today => "aujourd'hui", Date.tomorrow => "demain" }[date]
  end
end
