class SuperAdmin::MairieComptePolicy < DefaultSuperAdminPolicy
  alias index? team_member?
  alias new? super_admin_member?
  alias create? super_admin_member?
end
