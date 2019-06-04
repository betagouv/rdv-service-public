class Organisation < ApplicationRecord
  has_many :pros, dependent: :destroy
  has_many :sites, dependent: :destroy
  has_many :specialites, dependent: :destroy

  validates :name, presence: true
end
