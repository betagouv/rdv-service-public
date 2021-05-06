class Territory < ApplicationRecord
  include HasPhoneNumberConcern

  has_many :organisations, dependent: :destroy
  has_many :roles, class_name: "AgentTerritorialRole", dependent: :delete_all
  has_many :agents, through: :roles

  validates :departement_number, length: { maximum: 3 }, if: -> { departement_number.present? }
  validates :name, presence: true, if: -> { persisted? }
  validates :departement_number, uniqueness: true, allow_blank: true

  scope :with_agent, lambda { |agent|
    joins(:roles).where(agent_territorial_roles: { agent_id: agent.id })
  }
  scope :with_upcoming_rdvs, lambda {
    where(id: Organisation.with_upcoming_rdvs.distinct.select(:territory_id))
  }

  before_create :fill_name_for_departements

  def to_s
    "#{departement_number} - #{name}"
  end

  private

  def fill_name_for_departements
    return if name.present? || departement_number.blank?

    self.name = Departements::NAMES[departement_number]
  end
end
