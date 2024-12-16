class SuperAdmin::AgentTerritorialAccessRightPolicy < DefaultSuperAdminPolicy
  alias show? team_member?
  alias edit? team_member?
  alias update? team_member?
end
