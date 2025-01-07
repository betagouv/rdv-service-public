class Agent::RdvPlanPolicy < ApplicationPolicy
  def create?
    # TODO: utiliser la policy du user : il doit déjà exister dans l'orga
    true
  end
  alias new? create?
  alias edit? create?
  alias update? create?
end
