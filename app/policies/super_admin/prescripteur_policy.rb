class SuperAdmin::PrescripteurPolicy < DefaultSuperAdminPolicy
  alias show? team_member?
end
