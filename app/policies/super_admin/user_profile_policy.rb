class SuperAdmin::UserProfilePolicy < DefaultSuperAdminPolicy
  alias destroy? super_admin_member?
end
