class AgentTerritorialAccessRight < ApplicationRecord
  # Mixins
  has_paper_trail

  # Relations
  belongs_to :agent
  belongs_to :territory

  scope :allowing_anything, lambda {
    where("agent_territorial_access_rights.allow_to_manage_teams         IS TRUE OR
           agent_territorial_access_rights.allow_to_manage_access_rights IS TRUE OR
           agent_territorial_access_rights.allow_to_invite_agents        IS TRUE")
  }
end
