FactoryBot.define do
  factory :agent_trusted_device do
    agent
    token_digest { AgentTrustedDevice.digest(SecureRandom.hex(32)) }
    expires_at { AgentTrustedDevice::TRUST_DURATION.from_now }
  end
end
