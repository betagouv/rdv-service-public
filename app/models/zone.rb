class Zone < ApplicationRecord
  LEVEL_CITY = "city".freeze

  belongs_to :organisation

  validates :organisation, :level, :city_name, :city_code, presence: true
  validates :level, inclusion: { in: [LEVEL_CITY] }
  validates :city_code, uniqueness: true, if: :city?
  validate :coherent_city_code_departement

  delegate :departement, to: :organisation, allow_nil: true

  def city?
    level == LEVEL_CITY
  end

  protected

  def coherent_city_code_departement
    return true if city_code.blank? || departement.blank? || city_code.start_with?(departement)

    errors.add(:city_code, "doit commencer par le département de l'organisation")
  end
end
