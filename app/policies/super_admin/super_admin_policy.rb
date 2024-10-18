class SuperAdmin::SuperAdminPolicy < DefaultSuperAdminPolicy
  alias index? team_member?
  alias destroy? team_member?
end
