class Agents::OutlookSyncMailerPreview < ActionMailer::Preview
  def sync_disabled
    Agents::OutlookSyncMailer.with(
      agent: Agent.where.not(email: nil).last,
      error_description: "AADSTS700082: The refresh token has expired due to inactivity."
    ).sync_disabled
  end
end
