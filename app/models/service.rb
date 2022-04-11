# frozen_string_literal: true

class Service < ApplicationRecord
  # Attributes
  auto_strip_attributes :name, :short_name

  SECRETARIAT = "Secrétariat"
  SERVICE_SOCIAL = "Service social"
  PMI = "PMI (Protection Maternelle Infantile)"
  CONSEILLER_NUMERIQUE = "Conseiller Numérique"

  # Relations
  has_many :agents, dependent: :nullify
  has_many :motifs, dependent: :destroy

  # Validations
  validates :name, :short_name, presence: true, uniqueness: { case_sensitive: false }

  # Scopes
  scope :with_motifs, -> { where.not(name: SECRETARIAT) }
  scope :secretariat, -> { where(name: SECRETARIAT) }
  scope :ordered_by_name, -> { order(Arel.sql("unaccent(LOWER(name))")) }

  ## -

  def secretariat?
    name == SECRETARIAT
  end

  def service_social?
    name == SERVICE_SOCIAL
  end

  def pmi?
    name == PMI
  end

  def user_field_groups
    related_to_social? ? [:social] : []
  end

  def related_to_social?
    service_social? || name.parameterize.include?("social")
  end

  # This is the main toggle to enable or disable features for Conseillers Numériques (cnfs)
  # TODO: As the usage of this toggle grows, we might need to rethink it, and see if these changes
  # should be done via configuration, or something else
  def conseiller_numerique?
    name == CONSEILLER_NUMERIQUE
  end
end
