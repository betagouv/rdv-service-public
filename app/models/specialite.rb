class Specialite < ApplicationRecord
  has_many :pros
  validates :name, presence: true, uniqueness: { case_sensitive: false }
end
