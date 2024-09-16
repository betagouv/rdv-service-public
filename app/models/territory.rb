class Territory < ApplicationRecord
  has_paper_trail

  SPECIAL_NAMES = [
    MAIRIES_NAME = "Mairies".freeze,
    CNFS_NAME = "Conseillers Numériques".freeze,
    VISIOPLAINTE_NAME = "Visioplainte".freeze,
  ].freeze
  CN_DEPARTEMENT_NUMBER = "CN".freeze

  # Mixins
  include PhoneNumberValidation::HasPhoneNumber

  # Attributes
  auto_strip_attributes :name

  enum :sms_provider, {
    netsize: "netsize",
    send_in_blue: "send_in_blue",
    contact_experience: "contact_experience",
    sfr_mail2sms: "sfr_mail2sms",
    clever_technologies: "clever_technologies",
    orange_contact_everyone: "orange_contact_everyone",
  }, prefix: true

  # Relations
  has_many :teams, dependent: :destroy
  has_many :organisations, dependent: :destroy
  has_many :sectors, dependent: :restrict_with_error
  has_many :roles, class_name: "AgentTerritorialRole", dependent: :delete_all
  has_many :agent_territorial_access_rights, dependent: :destroy
  has_many :territory_services, dependent: :destroy
  has_and_belongs_to_many :motif_categories

  # Through relations
  has_many :organisations_agents, -> { distinct }, through: :organisations, source: :agents
  has_many :admin_agents, through: :roles, source: :agent
  has_many :zones, through: :sectors
  has_many :motifs, through: :organisations
  has_many :rdvs, through: :organisations
  has_many :receipts, through: :organisations
  has_many :user_profiles, through: :organisations
  has_many :users, -> { distinct }, through: :user_profiles
  has_many :services, through: :territory_services

  # Validations
  validates :departement_number, length: { maximum: 3 }, if: -> { departement_number.present? }
  validates :name, presence: true, if: -> { persisted? }
  validate do
    if name_changed? && name_was.in?(SPECIAL_NAMES)
      errors.add(:name, "Le nom de ce territoire lui donne des propriétés particulières et ne peut donc pas être changé")
    end
  end
  validate do
    if name_changed? && name.in?(SPECIAL_NAMES)
      errors.add(:name, "Ce nom ne peut pas être utilisé")
    end
  end

  # Hooks
  before_create :fill_name_for_departements

  # Scopes
  scope :with_upcoming_rdvs, lambda {
    where(id: Organisation.with_upcoming_rdvs.distinct.select(:territory_id))
  }
  scope :ordered_by_name, -> { order(Arel.sql("unaccent(LOWER(territories.name))")) }

  ## -

  OPTIONAL_RDV_FIELD_TOGGLES = {
    enable_context_field: :context,
  }.freeze

  OPTIONAL_RDV_WAITING_ROOM_FIELD_TOGGLES = {
    enable_waiting_room_mail_field: :mail_to_agent,
    enable_waiting_room_color_field: :change_rdv_color,
  }.freeze

  SOCIAL_FIELD_TOGGLES = {
    enable_caisse_affiliation_field: :caisse_affiliation,
    enable_affiliation_number_field: :affiliation_number,
    enable_family_situation_field: :family_situation,
    enable_number_of_children_field: :number_of_children,
    enable_case_number: :case_number,
    enable_address_details: :address_details,
  }.freeze

  OPTIONAL_FIELD_TOGGLES = {
    enable_notes_field: :notes,
    enable_logement_field: :logement,
  }.merge(SOCIAL_FIELD_TOGGLES).freeze

  def self.mairies
    find_by(name: MAIRIES_NAME)
  end

  def mairies?
    name == MAIRIES_NAME
  end

  def cn?
    name == CNFS_NAME
  end

  def sectorized?
    sectors.joins(:attributions).any? && motifs.active.sectorized.any?
  end

  def any_motifs_opened_for_prescription?
    motifs.bookable_by_everyone_or_agents_and_prescripteurs_or_invited_users.exists?
  end

  def any_social_field_enabled?
    attributes.slice(SOCIAL_FIELD_TOGGLES.keys).values.any?
  end

  def to_s
    [name, departement_number.presence].compact.join(" - ")
  end

  def waiting_room_enabled?
    OPTIONAL_RDV_WAITING_ROOM_FIELD_TOGGLES.keys.any? do |waiting_room_field|
      send(waiting_room_field)
    end
  end

  private

  DEPARTEMENTS_NAMES = CSV.read(Rails.root.join("lib/assets/departements_fr.csv"), headers: :first_row)
    .to_h { [_1["number"], _1["name"]] }

  def fill_name_for_departements
    return if name.present? || departement_number.blank?

    self.name = DEPARTEMENTS_NAMES[departement_number]
  end
end
