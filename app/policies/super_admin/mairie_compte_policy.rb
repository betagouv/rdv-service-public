class SuperAdmin::MairieComptePolicy < DefaultSuperAdminPolicy
  alias index? team_member?
  alias new? team_member?
  alias create? team_member?
end
