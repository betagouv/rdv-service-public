module Agents::TrustedDeviceConcern
  extend ActiveSupport::Concern

  private

  def agent_device_trusted?(agent)
    AgentTrustedDevice.trusted?(agent, cookies.encrypted[trusted_device_cookie_name(agent)])
  end

  def remember_agent_device!(agent)
    raw_token = AgentTrustedDevice.remember!(agent)
    cookies.encrypted[trusted_device_cookie_name(agent)] = {
      value: raw_token,
      expires: AgentTrustedDevice::TRUST_DURATION.from_now,
      httponly: true,
    }
  end

  def trusted_device_cookie_name(agent) = :"agent_trusted_device_#{agent.id}"
end
