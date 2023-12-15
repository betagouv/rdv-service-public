class SuperAdmin::AgentServicePolicy < DefaultSuperAdminPolicy
  alias show? team_member?
  alias destroy? team_member?
end
