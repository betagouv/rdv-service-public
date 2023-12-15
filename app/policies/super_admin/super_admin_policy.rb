class SuperAdmin::SuperAdminPolicy < DefaultSuperAdminPolicy
  alias index? team_member?
  alias show? team_member?
  alias new? team_member?
  alias create? privileges_for_record?
  alias edit? privileges_for_record?
  alias update? privileges_for_record?
  alias destroy? privileges_for_record?

  private

  def privileges_for_record?
    super_admin_member? || (record.support_member? && support_member?)
  end
end
