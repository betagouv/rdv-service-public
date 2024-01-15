class SuperAdmin::SuperAdminPolicy < DefaultSuperAdminPolicy
  def privileges_for_record?
    legacy_admin_member? || (record.support_member? && support_member?)
  end

  alias index? team_member?
  alias show? team_member?
  alias new? team_member?
  alias create? privileges_for_record?
  alias edit? privileges_for_record?
  alias update? privileges_for_record?
  alias destroy? privileges_for_record?
end
