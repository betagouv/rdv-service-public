class Territory < ApplicationRecord
  include HasPhoneNumberConcern

  has_many :organisations, dependent: :destroy
  has_many :roles, class_name: "AgentTerritorialRole", dependent: :delete_all
  has_many :agents, through: :roles

  validates :departement_number, length: { maximum: 3 }, if: -> { departement_number.present? }
  validates :name, presence: true, if: -> { persisted? }
  validate :unique_departement_number

  scope :with_agent, lambda { |agent|
    joins(:roles).where(agent_territorial_roles: { agent_id: agent.id })
  }
  scope :with_upcoming_rdvs, lambda {
    where(id: Organisation.with_upcoming_rdvs.distinct.pluck(:territory_id))
  }

  before_create :fill_name_for_departements

  def to_s
    "#{departement_number} - #{name}"
  end

  private

  def unique_departement_number
    return if departement_number.blank? || Territory
      .where.not(persisted? ? { id: id } : {})
      .where(departement_number: departement_number)
      .empty?

    errors.add(:base, I18n.t("activerecord.errors.models.territory.department_number_already_taken"))
  end

  def fill_name_for_departements
    return if name.present? || departement_number.blank?

    self.name = Departements::NAMES[departement_number]
  end
end
