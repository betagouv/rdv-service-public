class SuperAdmin::RdvPolicy < DefaultSuperAdminPolicy
  alias show? team_member?
end
