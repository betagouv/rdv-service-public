class SuperAdmin::TerritoryPolicy < DefaultSuperAdminPolicy
  alias index? team_member?
  alias show? team_member?
  alias edit? team_member?
  alias update? team_member?
  alias destroy? legacy_admin_member?
end
