class Sector < ApplicationRecord
  has_many :attributions, class_name: "SectorAttribution", dependent: :destroy
  has_many :organisations, through: :attributions
  has_many :zones

  validates :departement, :name, :human_id, presence: true
  validates :human_id, uniqueness: { scope: :departement }
  validate :coherent_city_code_departement

  scope :order_by_name, -> { order(Arel.sql("LOWER(name)")) }

  protected

  def coherent_city_code_departement
    # this substraction handles the absence of organisations too
    return true if organisations.pluck(:departement).uniq - [departement] == []

    errors.add(:departement, "doit correspondre aux départements des organisations attribuées")
  end
end
