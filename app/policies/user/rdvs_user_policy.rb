# frozen_string_literal: true

class User::RdvsUserPolicy < ApplicationPolicy
  alias current_user pundit_user

  def rdvs_user_belongs_to_user_or_relatives?
    current_user.available_users_for_rdv.pluck(:id).include? record.user_id
  end

  def create?
    # J'ai volontairement pas délégué not_revoked du rdv à la participation pour des raisons de clarté
    rdvs_user_belongs_to_user_or_relatives? && record.rdv.not_revoked?
  end

  def cancel?
    rdvs_user_belongs_to_user_or_relatives? && record.cancellable_by_user?
  end

  class Scope < Scope
    alias current_user pundit_user

    def resolve
      scope
        .where(user_id: current_user.available_users_for_rdv.pluck(:id))
    end
  end
end
