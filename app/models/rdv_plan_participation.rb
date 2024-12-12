class RdvPlanParticipation < ApplicationRecord
  belongs_to :user
  belongs_to :rdv_plan
end
