class SuperAdmin::AgentPolicy < DefaultSuperAdminPolicy
  alias sign_in_as? team_member?
  alias invite? team_member?
  alias index? team_member?
  alias show? team_member?
  alias create? team_member?
  alias new? team_member?
  alias edit? team_member?
  alias update? team_member?
  alias destroy? team_member?
end
