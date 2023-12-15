class SuperAdmin::MairieComptePolicy < DefaultSuperAdminPolicy
  alias index? super_admin_member?
  alias new? super_admin_member?
  alias create? super_admin_member?
end
