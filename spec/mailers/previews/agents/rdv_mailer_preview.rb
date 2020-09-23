class Agents::RdvMailerPreview < ActionMailer::Preview
  def rdv_starting_soon_created
    rdv = Rdv.not_cancelled.last
    rdv.starts_at = 2.hours.from_now
    Agents::RdvMailer.rdv_starting_soon_created(rdv, rdv.agents.first)
  end

  def rdv_starting_soon_cancelled
    rdv = Rdv.cancelled.last || Rdv.last
    rdv.starts_at = 2.hours.from_now
    rdv.status = :excused
    Agents::RdvMailer
      .rdv_starting_soon_cancelled(rdv, rdv.agents.first, "[Agent] Jean MICHEL")
  end

  def rdv_starting_soon_date_updated
    rdv = Rdv.not_cancelled.last
    rdv.starts_at = Date.today + 10.days + 10.hours
    rdv.define_singleton_method(:starts_at_before_last_save) { 2.hours.from_now }
    Agents::RdvMailer.rdv_starting_soon_date_updated(
      rdv,
      rdv.agents.first,
      "[Agent] Jean MICHEL",
      2.hours.from_now
    )
  end
end
