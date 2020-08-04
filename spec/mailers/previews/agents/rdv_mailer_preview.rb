class Agents::RdvMailerPreview < ActionMailer::Preview
  def rdv_starting_soon_created
    rdv = Rdv.active.not_cancelled.last
    rdv.starts_at = 2.hours.from_now
    Agents::RdvMailer.rdv_starting_soon_created(rdv, rdv.agents.first)
  end
end
