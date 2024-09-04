class Zone < ApplicationRecord
  # Attributes
  # TODO: make it an enum
  LEVEL_CITY = "city".freeze
  LEVEL_STREET = "street".freeze
  LEVELS = [LEVEL_CITY, LEVEL_STREET].freeze

  attr_accessor :city_label, :street_label # used in zone form

  # Relations
  belongs_to :sector
  delegate :territory, to: :sector

  # Validations
  validates :level, :city_name, :city_code, presence: true
  validates :level, inclusion: { in: LEVELS }
  validate :coherent_city_code_departement
  # level city validations
  validates :city_code, uniqueness: { scope: :sector }, if: :level_city?
  validates :street_ban_id, :street_name, absence: true, if: :level_city?
  # level street validations
  validates :street_ban_id, :street_name, presence: true, if: :level_street?
  validates :street_ban_id, uniqueness: { scope: :sector }, if: :level_street?
  validate :coherent_street_ban_id, if: :level_street?

  # Scopes
  scope :cities, -> { where(level: LEVEL_CITY) }
  scope :streets, -> { where(level: LEVEL_STREET) }

  ## -

  def level_city?
    level == LEVEL_CITY
  end

  def level_street?
    level == LEVEL_STREET
  end

  def name
    if level_city?
      city_name
    else
      street_name
    end
  end

  protected

  def coherent_city_code_departement
    return true if city_code.blank? \
      || sector&.territory&.departement_number.blank? \
      || city_code.start_with?(sector.territory.departement_number)

    errors.add(:base, "La commune #{city_name} n'appartient pas au département #{sector&.territory&.departement_number}")
  end

  def coherent_street_ban_id
    expected_prefix = "#{city_code}_"
    return true if street_ban_id.blank? || city_code.blank? || street_ban_id.start_with?(expected_prefix)

    errors.add(:base, "La rue #{street_name} n'appartient pas à la ville #{city_name}")
  end
end
