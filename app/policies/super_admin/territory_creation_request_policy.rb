class SuperAdmin::TerritoryCreationRequestPolicy < DefaultSuperAdminPolicy
  alias index? team_member?
  alias edit? team_member?
  alias update? team_member?
end
