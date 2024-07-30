class Organisation < ApplicationRecord
  # Mixins
  has_paper_trail
  include WebhookDeliverable

  # Attributes
  auto_strip_attributes :email, :name
  enum verticale: {
    rdv_insertion: "rdv_insertion",
    rdv_solidarites: "rdv_solidarites",
    rdv_aide_numerique: "rdv_aide_numerique",
    rdv_mairie: "rdv_mairie",
  }

  # Relations
  belongs_to :territory
  has_many :lieux, dependent: :destroy
  has_many :motifs, dependent: :destroy
  has_many :rdvs, dependent: :restrict_with_error
  has_many :webhook_endpoints, dependent: :destroy
  has_many :sector_attributions, dependent: :destroy
  has_many :plage_ouvertures, dependent: :destroy
  has_many :agent_roles, dependent: :delete_all # skips last admin validation
  has_many :user_profiles, dependent: :restrict_with_error

  # Through relations
  has_many :sectors, through: :sector_attributions
  # we specify dependent: :destroy because by default it will be deleted (dependent: :delete)
  # and we need to destroy to trigger the callbacks on the model
  has_many :users, through: :user_profiles, dependent: :destroy
  has_many :agents, through: :agent_roles, dependent: :destroy
  has_many :referent_assignations, through: :users
  has_many :receipts, dependent: :destroy

  accepts_nested_attributes_for :agent_roles
  accepts_nested_attributes_for :territory

  # Delegates
  delegate :departement_number, to: :territory

  # Validation
  validates :name, presence: true, uniqueness: { scope: :territory }
  validates :external_id, uniqueness: { scope: :territory, allow_nil: true }
  validate :validate_organisation_phone_number

  # Scopes
  scope :attributed_to_sectors, lambda { |sectors:, most_relevant: false|
    attributions = SectorAttribution
      .level_organisation
      .where(sector_id: sectors.pluck(:id))

    # if most relevant we take the attributions from the sector with the least
    # attributed organisations
    if most_relevant
      attributions = attributions
        .group_by(&:sector_id)
        .min_by(1) { |_sector_id, attrs| attrs.length }
        .flat_map(&:last)
    end

    where(id: attributions.pluck(:organisation_id))
  }
  scope :ordered_by_name, -> { order(Arel.sql("unaccent(LOWER(organisations.name))")) }
  scope :contactable, lambda {
    where.not(phone_number: ["", nil])
      .or(where.not(website: ["", nil]))
      .or(where.not(email: ["", nil]))
  }
  scope :with_upcoming_rdvs, lambda {
    where(id: Rdv.future.distinct.select(:organisation_id))
  }

  ## -

  def domain
    case verticale.to_sym
    when :rdv_aide_numerique
      Domain::RDV_AIDE_NUMERIQUE
    when :rdv_mairie
      Domain::RDV_MAIRIE
    else
      Domain::RDV_SOLIDARITES
    end
  end

  def slug
    name.parameterize[..80]
  end

  def validate_organisation_phone_number
    return if phone_number_is_valid?

    errors.add(:phone_number, :invalid)
  end

  def phone_number_is_valid?
    # Blank, Valid Phone, 4 digits phone (organisations only)
    phone_number.blank? || Phonelib.parse(phone_number).valid? || phone_number.match(/^\d{4}$/)
  end

  def humanized_phone_number
    Phonelib.parse(phone_number).national
  end

  def sectorized?
    sector_attributions.any? && motifs.active.sectorized.any?
  end
end
