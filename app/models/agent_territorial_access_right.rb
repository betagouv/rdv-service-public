class AgentTerritorialAccessRight < ApplicationRecord
  # Mixins
  has_paper_trail

  # Relations
  belongs_to :agent
  belongs_to :territory

  scope :without_any_rights_allowed, lambda {
    where(
      allow_to_manage_teams: false,
      allow_to_manage_access_rights: false,
      allow_to_invite_agents: false
    )
  }
  scope :with_some_rights_allowed, -> { without_any_rights_allowed.invert_where }
end
