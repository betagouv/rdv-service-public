# frozen_string_literal: true

class AgentRole < ApplicationRecord
  LEVEL_BASIC = "basic"
  LEVEL_ADMIN = "admin"
  LEVELS = [LEVEL_BASIC, LEVEL_ADMIN].freeze

  self.table_name = "agents_organisations"

  belongs_to :agent
  belongs_to :organisation

  validates :level, inclusion: { in: LEVELS }
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

  before_destroy :organisation_have_at_least_one_admin_before_destroy

  scope :level_basic, -> { where(level: LEVEL_BASIC) }
  scope :level_admin, -> { where(level: LEVEL_ADMIN) }

  accepts_nested_attributes_for :agent

  def basic?
    level == LEVEL_BASIC
  end

  def admin?
    level == LEVEL_ADMIN
  end

  def can_access_others_planning?
    admin? || agent.service.secretariat?
  end

  private

  def organisation_cannot_change
    return if !organisation_id_changed? || new_record?

    errors.add(:organisation_id, "Vous ne pouvez pas changer ce rôle d'organisation")
  end

  def organisation_have_at_least_one_admin
    return if new_record? || level == LEVEL_ADMIN || organisation.agent_roles.where.not(id: id).any?(&:admin?)

    errors.add(:base, "Il doit toujours y avoir au moins un agent Admin par organisation")
  end

  def organisation_have_at_least_one_admin_before_destroy
    return if organisation.agent_roles.where.not(id: id).any?(&:admin?)

    errors.add(:base, "Il doit toujours y avoir au moins un agent Admin par organisation")
    throw :abort
  end
end
