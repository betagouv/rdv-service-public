class SuperAdmin::OauthApplicationPolicy < DefaultSuperAdminPolicy
  alias index? legacy_admin_member?
  alias show? legacy_admin_member?
  alias new? legacy_admin_member?
  alias create? legacy_admin_member?
  alias edit? legacy_admin_member?
  alias update? legacy_admin_member?
  alias destroy? legacy_admin_member?
  alias regenerate_secret? legacy_admin_member?
end
