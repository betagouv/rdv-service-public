class SuperAdmin::AgentRolePolicy < DefaultSuperAdminPolicy
  alias show? team_member?
  alias edit? team_member?
  alias update? team_member?
  alias destroy? team_member?
end
