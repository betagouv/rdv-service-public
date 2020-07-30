class Service < ApplicationRecord
  has_many :agents, dependent: :nullify
  has_many :motifs, dependent: :destroy
  has_many :motif_libelles, dependent: :destroy
  validates :name, :short_name, presence: true, uniqueness: { case_sensitive: false }
  SECRETARIAT = "Secrétariat".freeze
  SERVICE_SOCIAL = "Service social".freeze

  scope :with_motifs, -> { where.not(name: SECRETARIAT) }
  scope :secretariat, -> { where(name: SECRETARIAT).first }

  scope :searchable, lambda { |organisations|
    where(id: Motif.searchable(organisations).pluck(:service_id).uniq)
  }

  def secretariat?
    name == SECRETARIAT
  end

  def service_social?
    name == SERVICE_SOCIAL
  end
end
