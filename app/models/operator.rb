class Operator < ApplicationRecord
  has_many :territories, dependent: :nullify
end
