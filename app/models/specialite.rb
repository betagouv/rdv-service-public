class Specialite < ApplicationRecord
  belongs_to :organisation
  has_many :pros
end
