class User::UserPolicy < ApplicationPolicy
  alias current_user pundit_user

  def user_is_responsible?
    record.responsible_id == current_user.id
  end

  alias new? user_is_responsible?
  alias create? user_is_responsible?

  def current_user_or_responsible?
    record.id == current_user.id || user_is_responsible?
  end

  alias show? current_user_or_responsible?
  alias edit? current_user_or_responsible?
  alias update? current_user_or_responsible?
  alias destroy? current_user_or_responsible?

  class Scope < Scope
    alias current_user pundit_user

    def resolve
      scope
        .where(id: current_user.id)
        .or(User.where(responsible_id: current_user.id))
    end
  end
end
