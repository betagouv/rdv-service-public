class Service < ApplicationRecord
  has_many :agents, dependent: :nullify
  has_many :motifs, dependent: :destroy
  validates :name, presence: true, uniqueness: { case_sensitive: false }
  scope :with_motifs, -> { where.not(name: 'Secrétariat') }
end
