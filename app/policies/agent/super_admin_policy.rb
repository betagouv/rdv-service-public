class Agent::SuperAdminPolicy < ApplicationPolicy
  include CurrentAgentInPolicyConcern

  def sign_in_as?
    @record.support_member? || @record.legacy_admin_member?
  end
end
