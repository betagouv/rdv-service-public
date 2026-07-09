class Service < ApplicationRecord
  # Mixins
  has_paper_trail

  # Attributes
  auto_strip_attributes :name, :short_name

  SERVICE_SOCIAL = "Service social".freeze
  PMI = "PMI (Protection Maternelle Infantile)".freeze
  CONSEILLER_NUMERIQUE = "Conseiller Numérique".freeze
  MAIRIE = "Mairie".freeze

  # Relations
  has_many :agent_services, dependent: :restrict_with_error
  has_many :agents, through: :agent_services
  has_many :motifs, dependent: :restrict_with_error
  has_many :territory_services, dependent: :restrict_with_error
  has_many :territories, through: :territory_services

  # Validations
  validates :name, uniqueness: { case_sensitive: false }
  validate :validate_name_length
  validate :validate_short_name_length

  # Scopes
  default_scope { order(Arel.sql("unaccent(LOWER(services.name))")) }

  ## -

  def service_social?
    name == SERVICE_SOCIAL
  end

  def pmi?
    name == PMI
  end

  def conseiller_numerique?
    name == CONSEILLER_NUMERIQUE
  end

  def mairie?
    name == MAIRIE
  end

  def user_field_groups
    related_to_social? ? [:social] : []
  end

  def related_to_social?
    service_social? || name.parameterize.include?("social")
  end

  private

  def validate_name_length
    if name.to_s.length > 60
      errors.add(:name, "ne doit pas dépasser 60 caractères.")
    end

    if name.to_s.length < 2
      errors.add(:name, "doit contenir au moins 2 caractères.")
    end
  end

  def validate_short_name_length
    if short_name.to_s.length > 40
      errors.add(:short_name, "ne doit pas dépasser 40 caractères.")
    end

    if short_name.to_s.length < 2
      errors.add(:short_name, "doit contenir au moins 2 caractères.")
    end
  end
end
