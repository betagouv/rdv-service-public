class AgentsRdv < ApplicationRecord
  belongs_to :rdv, touch: true
  belongs_to :agent
end
