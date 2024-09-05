class Sector < ApplicationRecord
  # Attributes
  auto_strip_attributes :name

  # Relations
  belongs_to :territory
  has_many :attributions, class_name: "SectorAttribution", dependent: :destroy
  has_many :zones, dependent: :destroy

  # Through relations
  has_many :organisations, through: :attributions

  # Validations
  validates :name, :human_id, presence: true
  validates :human_id, uniqueness: { scope: :territory_id }
  validate :coherent_territory

  # Scopes
  scope :ordered_by_name, -> { order(Arel.sql("unaccent(LOWER(sectors.name))")) }
  scope :attributed_to_organisation, lambda { |organisation|
    joins(:attributions)
      .where(sector_attributions: { organisation_id: organisation.id, level: SectorAttribution::LEVEL_ORGANISATION })
  }

  ## -

  protected

  def coherent_territory
    # this substraction handles the absence of organisations too
    return true if organisations.all? { _1.territory_id == territory_id }

    errors.add(:territory_id, "doit correspondre aux départements des organisations attribuées")
  end
end
