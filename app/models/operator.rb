class Operator < ApplicationRecord
  has_many :territories, dependent: :nullify
  has_many :operator_managers, dependent: :destroy
end
