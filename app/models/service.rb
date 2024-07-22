class Service < ApplicationRecord
  # Mixins
  has_paper_trail

  # Attributes
  auto_strip_attributes :name, :short_name

  SECRETARIAT = "Secrétariat".freeze
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
  validates :name, :short_name, presence: true, uniqueness: { case_sensitive: false }

  # Scopes
  default_scope { ordered_by_name }

  ## -

  def self.secretariat
    find_by!(name: SECRETARIAT)
  end

  def secretariat?
    name == SECRETARIAT
  end

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
end
