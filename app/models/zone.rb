class Zone < ApplicationRecord
  LEVEL_CITY = "city".freeze

  belongs_to :sector

  validates :sector, :level, :city_name, :city_code, presence: true
  validates :level, inclusion: { in: [LEVEL_CITY] }
  validates :city_code, uniqueness: { scope: :sector }, if: :city?
  validate :coherent_city_code_departement

  attr_accessor :city_label # used in zone form

  def city?
    level == LEVEL_CITY
  end

  protected

  def coherent_city_code_departement
    return true if city_code.blank? || sector&.departement.blank? || city_code.start_with?(sector&.departement)

    errors.add(:city_code, "doit commencer par le département du secteur")
  end
end
