class AgentRole < ApplicationRecord
  # Mixins
  has_paper_trail
  include WebhookDeliverable

  # Attributes
  ACCESS_LEVEL_BASIC = "basic".freeze
  ACCESS_LEVEL_ADMIN = "admin".freeze
  ACCESS_LEVEL_INTERVENANT = "intervenant".freeze
  ACCESS_LEVELS = [ACCESS_LEVEL_BASIC, ACCESS_LEVEL_ADMIN].freeze
  ACCESS_LEVELS_WITH_INTERVENANT = [ACCESS_LEVEL_BASIC, ACCESS_LEVEL_ADMIN, ACCESS_LEVEL_INTERVENANT].freeze

  enum access_level: {
    basic: "basic", # Basic Role
    admin: "admin", # Admin Role
    intervenant: "intervenant", # Intervenant Role
  }

  # Relations
  belongs_to :agent
  belongs_to :organisation

  # Through relations
  has_many :webhook_endpoints, through: :organisation

  accepts_nested_attributes_for :agent

  # Validation
  validate :organisation_cannot_change
  validate :organisation_have_at_least_one_admin

  # Customize the uniqueness error message. This class needs to be declared before the validates :agent, uniqueness: line.
  class UniquenessValidator < ActiveRecord::Validations::UniquenessValidator
    def validate_each(record, attribute, value)
      super
      # Refine the “agent: taken” error to indicate if agent has only been invited to the app
      return if record.errors.details[:agent]&.select { _1[:error] == :taken }.blank?

      record.errors.delete(:agent)
      new_error = value.invitation_accepted_at.present? ? :taken_existing : :taken_invited
      record.errors.add(:agent, new_error, email: value.email)
    end
  end
  validates :agent, uniqueness: { scope: :organisation }

  # Hooks
  before_destroy :organisation_have_at_least_one_admin_before_destroy

  # Scopes
  scope :access_level_basic, -> { where(access_level: :basic) }
  scope :access_level_admin, -> { where(access_level: :admin) }

  ## -

  def can_access_others_planning?
    admin? || agent.secretaire?
  end

  private

  def organisation_cannot_change
    return if !organisation_id_changed? || new_record?

    errors.add(:organisation_id, "Vous ne pouvez pas changer ce rôle d'organisation")
  end

  def organisation_have_at_least_one_admin
    return if new_record? || admin? || organisation.agent_roles.where.not(id: id).any?(&:admin?)

    errors.add(:base, "Il doit toujours y avoir au moins un agent Admin par organisation")
  end

  def organisation_have_at_least_one_admin_before_destroy
    return if organisation.agent_roles.where.not(id: id).any?(&:admin?)

    errors.add(:base, "Il doit toujours y avoir au moins un agent Admin par organisation")
    throw :abort
  end
end
