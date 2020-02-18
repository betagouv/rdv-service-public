class MotifLibelle < ApplicationRecord
  belongs_to :service

  default_scope { order("LOWER(name)") }
end
