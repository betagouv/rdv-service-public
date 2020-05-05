class RdvsUser < ApplicationRecord
  belongs_to :rdv, touch: true, inverse_of: :rdvs_users
  belongs_to :user
end
