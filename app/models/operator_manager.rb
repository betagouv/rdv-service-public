class OperatorManager < ApplicationRecord
  devise :authenticatable

  belongs_to :operator
end
