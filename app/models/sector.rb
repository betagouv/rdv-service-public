class Sector < ApplicationRecord
  belongs_to :territory
  has_many :attributions, class_name: "SectorAttribution", dependent: :destroy
  has_many :organisations, through: :attributions
  has_many :zones, dependent: :destroy

  validates :name, :human_id, presence: true
  validates :human_id, uniqueness: { scope: :territory_id }
  validate :coherent_territory

  scope :order_by_name, -> { order(Arel.sql("LOWER(sectors.name)")) }

  scope :attributed_to_organisation, lambda { |organisation|
    joins(:attributions)
      .where(sector_attributions: { organisation_id: organisation.id, level: SectorAttribution::LEVEL_ORGANISATION })
  }

  protected

  def coherent_territory
    # this substraction handles the absence of organisations too
    return true if organisations.all? { _1.territory_id == territory_id }

    errors.add(:territory_id, "doit correspondre aux départements des organisations attribuées")
  end
end
