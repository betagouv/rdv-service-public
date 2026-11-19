class Agents::CaldavSyncMailerPreview < ActionMailer::Preview
  def sync_disabled_incompatible_server
    agent = Agent.new(email: "francois@factice.cool")
    agent.readonly!

    Agents::CaldavSyncMailer.with(agent:).sync_disabled_incompatible_server
  end
end
