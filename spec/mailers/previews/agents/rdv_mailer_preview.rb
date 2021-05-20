# frozen_string_literal: true

class Agents::RdvMailerPreview < ActionMailer::Preview
  def rdv_created
    rdv = Rdv.not_cancelled.last
    rdv.starts_at = 2.hours.from_now
    Agents::RdvMailer.rdv_created(rdv, rdv.agents.first)
  end

  def rdv_cancelled
    rdv = Rdv.cancelled.last || Rdv.last
    rdv.starts_at = 2.hours.from_now
    rdv.status = :excused
    Agents::RdvMailer
      .rdv_cancelled(rdv, rdv.agents.first, "[Agent] Jean MICHEL")
  end

  def rdv_date_updated
    rdv = Rdv.not_cancelled.last
    rdv.starts_at = Date.today + 10.days + 10.hours
    Agents::RdvMailer.rdv_date_updated(
      rdv,
      rdv.agents.first,
      "[Agent] Jean MICHEL",
      2.hours.from_now
    )
  end
end
