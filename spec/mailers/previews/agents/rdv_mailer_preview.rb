class Agents::RdvMailerPreview < ActionMailer::Preview
  def rdv_created
    rdv = Rdv.joins(:users).not_cancelled.last
    rdv.starts_at = 2.hours.from_now

    rdv_mailer(rdv).rdv_created
  end

  def rdv_revoked
    rdv = Rdv.joins(:users).last
    rdv.status = :revoked

    rdv_mailer(rdv).rdv_cancelled
  end

  def rdv_cancelled_by_agent
    rdv = Rdv.joins(:users).last
    rdv.status = :excused
    rdv_mailer(rdv).rdv_cancelled
  end

  def rdv_cancelled_by_user
    rdv = Rdv.joins(:users).last
    rdv.status = :excused

    rdv_mailer(rdv, rdv.users.first).rdv_cancelled
  end

  def rdv_updated
    rdv = Rdv.joins(:users).not_cancelled.last
    rdv.starts_at = Time.zone.today + 10.days + 10.hours

    rdv_mailer(rdv).rdv_updated(old_starts_at: 2.hours.from_now, lieu_id: nil)
  end

  private

  def rdv_mailer(rdv, author = rdv.agents.first)
    Agents::RdvMailer.with(rdv: rdv, agent: rdv.agents.first, author: author)
  end
end
