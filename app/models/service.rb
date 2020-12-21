class Service < ApplicationRecord
  has_many :agents, dependent: :nullify
  has_many :motifs, dependent: :destroy
  has_many :motif_libelles, dependent: :destroy
  validates :name, :short_name, presence: true, uniqueness: { case_sensitive: false }
  SECRETARIAT = "Secrétariat".freeze
  SERVICE_SOCIAL = "Service social".freeze

  scope :with_motifs, -> { where.not(name: SECRETARIAT) }
  scope :secretariat, -> { where(name: SECRETARIAT).first }
  scope :ordered_by_name, -> { order(Arel.sql("unaccent(LOWER(name))")) }

  def secretariat?
    name == SECRETARIAT
  end

  def service_social?
    name == SERVICE_SOCIAL
  end

  def user_field_groups
    related_to_social? ? [:social] : []
  end

  def related_to_social?
    service_social? || name.parameterize.include?("social")
  end
end
