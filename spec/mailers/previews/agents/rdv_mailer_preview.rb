# frozen_string_literal: true

class Agents::RdvMailerPreview < ActionMailer::Preview
  def rdv_created
    rdv = Rdv.not_cancelled.last
    rdv.starts_at = 2.hours.from_now
    Agents::RdvMailer.rdv_created(rdv.payload(:create), rdv.agents.first)
  end

  def rdv_revoked
    rdv = Rdv.last
    rdv.status = :revoked
    Agents::RdvMailer
      .rdv_cancelled(rdv.payload(:destroy), rdv.agents.first, rdv.agents.first)
  end

  def rdv_cancelled_by_agent
    rdv = Rdv.last
    rdv.status = :excused
    Agents::RdvMailer
      .rdv_cancelled(rdv.payload(:destroy), rdv.agents.first, rdv.agents.first)
  end

  def rdv_cancelled_by_user
    rdv = Rdv.last
    rdv.status = :excused
    Agents::RdvMailer
      .rdv_cancelled(rdv.payload(:destroy), rdv.agents.first, rdv.users.first)
  end

  def rdv_date_updated
    rdv = Rdv.not_cancelled.last
    rdv.starts_at = Time.zone.today + 10.days + 10.hours
    Agents::RdvMailer.rdv_date_updated(
      rdv.payload(:update),
      rdv.agents.first,
      rdv.agents.first,
      2.hours.from_now
    )
  end
end
