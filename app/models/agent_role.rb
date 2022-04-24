# frozen_string_literal: true

class AgentRole < ApplicationRecord
  self.table_name = "agents_organisations" # TODO: sync the model and table name

  # Attributes
  # TODO: make it an enum
  LEVEL_BASIC = "basic"
  LEVEL_ADMIN = "admin"
  LEVELS = [LEVEL_BASIC, LEVEL_ADMIN].freeze

  # Relations
  belongs_to :agent
  belongs_to :organisation

  accepts_nested_attributes_for :agent

  # Validation
  validates :level, inclusion: { in: LEVELS }
  validate :organisation_cannot_change
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

  # Scopes
  scope :level_basic, -> { where(level: LEVEL_BASIC) }
  scope :level_admin, -> { where(level: LEVEL_ADMIN) }

  ## -

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
end
