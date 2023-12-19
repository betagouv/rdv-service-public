class SuperAdmin::MotifPolicy < DefaultSuperAdminPolicy
  alias index? team_member?
  alias show? team_member?
  alias create? legacy_admin_member?
  alias new? legacy_admin_member?
  alias edit? legacy_admin_member?
  alias update? legacy_admin_member?
  alias destroy? legacy_admin_member?
end
