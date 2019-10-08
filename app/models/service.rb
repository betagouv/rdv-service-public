class Service < ApplicationRecord
  has_many :pros, dependent: :nullify
  has_many :motifs, dependent: :destroy
  belongs_to :organisation
  validates :name, presence: true, uniqueness: { case_sensitive: false }
end
