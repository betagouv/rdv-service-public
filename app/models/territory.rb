class Territory < ApplicationRecord
  include HasPhoneNumberConcern

  has_many :organisations, dependent: :destroy
  has_many :roles, class_name: "AgentTerritorialRole", dependent: :delete_all
  has_many :agents, through: :roles

  validates :departement_number, length: { maximum: 3 }, if: -> { departement_number.present? }
  validates :name, presence: true, if: -> { persisted? }
  validates :departement_number, uniqueness: true, allow_blank: true
  validate :sms_configuration_match_provider

  scope :with_agent, lambda { |agent|
    joins(:roles).where(agent_territorial_roles: { agent_id: agent.id })
  }
  scope :with_upcoming_rdvs, lambda {
    where(id: Organisation.with_upcoming_rdvs.distinct.select(:territory_id))
  }

  enum sms_provider: { netsize: "netsize", send_in_blue: "send_in_blue" }, _prefix: true

  FIELDS_FOR_SMS_CONFIGURATION = {
    send_in_blue: ["api_key"],
    netsize: %w[api_url user_pwd]
  }.freeze

  before_create :fill_name_for_departements

  def to_s
    "#{departement_number} - #{name}"
  end

  private

  def fill_name_for_departements
    return if name.present? || departement_number.blank?

    self.name = Departements::NAMES[departement_number]
  end

  def sms_configuration_match_provider
    return true if sms_provider.blank?
    return true if (missing_keys = missing_configuration_keys).empty?

    errors.add(:sms_configuration, "doit contenir les valeurs pour #{missing_keys}")
  end

  def missing_configuration_keys
    FIELDS_FOR_SMS_CONFIGURATION[sms_provider.to_sym] - (sms_configuration.keys || [])
  end
end
