class SuperAdmin::LieuPolicy < DefaultSuperAdminPolicy
  alias index? team_member?
  alias show? team_member?
  alias create? legacy_admin_member?
  alias new? legacy_admin_member?
  alias edit? team_member?
  alias update? team_member?
  alias destroy? legacy_admin_member?
end
