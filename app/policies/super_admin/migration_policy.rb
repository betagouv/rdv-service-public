class SuperAdmin::MigrationPolicy < DefaultSuperAdminPolicy
  alias create? team_member?
  alias new? team_member?
end
