class SuperAdmin::UserPolicy < DefaultSuperAdminPolicy
  alias index? team_member?
  alias show? team_member?
  alias create? super_admin_member?
  alias new? super_admin_member?
  alias edit? super_admin_member?
  alias update? super_admin_member?
  alias destroy? super_admin_member?
end
