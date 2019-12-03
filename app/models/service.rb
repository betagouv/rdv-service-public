class Service < ApplicationRecord
  has_many :agents, dependent: :nullify
  has_many :motifs, dependent: :destroy
  has_many :motif_libelles, dependent: :destroy
  validates :name, presence: true, uniqueness: { case_sensitive: false }
  SECRETARIAT = 'Secrétariat'.freeze

  scope :with_motifs, -> { where.not(name: SECRETARIAT) }

  def secretariat?
    name == SECRETARIAT
  end
end
