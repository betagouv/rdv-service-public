class AgentTrustedDevice < ApplicationRecord
  TRUST_DURATION = 7.days

  belongs_to :agent

  validates :token_digest, presence: true, uniqueness: true
  validates :expires_at, presence: true

  scope :active, -> { where(expires_at: Time.zone.now..) }

  def self.remember!(agent)
    raw_token = SecureRandom.hex(32)
    create!(agent:, token_digest: digest(raw_token), expires_at: TRUST_DURATION.from_now)
    raw_token
  end

  def self.trusted?(agent, raw_token)
    return false if raw_token.blank?

    active.exists?(agent:, token_digest: digest(raw_token))
  end

  def self.digest(raw_token)
    Digest::SHA256.hexdigest(raw_token)
  end

  def self.cookie_name(agent) = :"agent_trusted_device_#{agent.id}"

  def self.trusted_by_cookie?(agent, cookies)
    trusted?(agent, cookies.encrypted[cookie_name(agent)])
  end

  def self.remember_by_cookie!(agent, cookies)
    raw_token = remember!(agent)
    cookies.encrypted[cookie_name(agent)] = {
      value: raw_token,
      expires: TRUST_DURATION.from_now,
      httponly: true,
    }
  end
end
