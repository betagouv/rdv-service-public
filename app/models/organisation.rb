class Organisation < ApplicationRecord
  has_many :pros
  has_many :sites
end
