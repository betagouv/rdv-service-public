class SuperAdmin::OauthApplicationPolicy < DefaultSuperAdminPolicy
  alias index? legacy_admin_member?
  alias show? legacy_admin_member?
end
