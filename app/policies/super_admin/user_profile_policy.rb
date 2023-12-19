class SuperAdmin::UserProfilePolicy < DefaultSuperAdminPolicy
  alias destroy? legacy_admin_member?
end
