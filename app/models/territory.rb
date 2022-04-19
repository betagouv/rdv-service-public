# frozen_string_literal: true

class Territory < ApplicationRecord
  # Mixins
  include PhoneNumberValidation::HasPhoneNumber

  # Attributes
  auto_strip_attributes :name

  enum sms_provider: {
    netsize: "netsize",
    send_in_blue: "send_in_blue",
    contact_experience: "contact_experience",
    sfr_mail2sms: "sfr_mail2sms",
    clever_technologies: "clever_technologies",
    orange_contact_everyone: "orange_contact_everyone"
  }, _prefix: true

  # Relations
  has_many :teams, dependent: :destroy
  has_many :organisations, dependent: :destroy
  has_many :sectors, dependent: :destroy
  has_many :roles, class_name: "AgentTerritorialRole", dependent: :delete_all

  # Through relations
  has_many :organisations_agents, through: :organisations, source: :agents
  has_many :agents, through: :roles
  has_many :zones, through: :sectors

  # Validations
  validates :departement_number, length: { maximum: 3 }, if: -> { departement_number.present? }
  validates :name, presence: true, if: -> { persisted? }
  validates :departement_number, uniqueness: true, allow_blank: true

  # Hooks
  before_create :fill_name_for_departements

  # Scopes
  scope :with_upcoming_rdvs, lambda {
    where(id: Organisation.with_upcoming_rdvs.distinct.select(:territory_id))
  }

  ## -

  OPTIONAL_RDV_FIELD_TOGGLES = {
    enable_context_field: :context
  }.freeze

  OPTIONAL_MOTIF_FIELD_TOGGLES = {
    enable_motif_categories_field: :category
  }.freeze

  SOCIAL_FIELD_TOGGLES = {
    enable_caisse_affiliation_field: :caisse_affiliation,
    enable_affiliation_number_field: :affiliation_number,
    enable_family_situation_field: :family_situation,
    enable_number_of_children_field: :number_of_children,
    enable_case_number: :case_number,
    enable_address_details: :address_details,
    enable_notes_field: :notes,
    enable_logement_field: :logement
  }.freeze

  def any_social_field_enabled?
    attributes.slice(SOCIAL_FIELD_TOGGLES.keys).values.any?
  end

  def to_s
    "#{departement_number} - #{name}"
  end

  private

  def fill_name_for_departements
    return if name.present? || departement_number.blank?

    self.name = Departements::NAMES[departement_number]
  end
end
