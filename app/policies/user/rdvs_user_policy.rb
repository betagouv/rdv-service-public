# frozen_string_literal: true

class User::RdvsUserPolicy < ApplicationPolicy
  alias current_user pundit_user

  def rdvs_user_belongs_to_user_or_relatives?
    current_user.available_users_for_rdv.pluck(:id).include? record.user_id
  end

  def new?
    return false if record.rdv.revoked?

    record.rdv.collectif? && record.rdv.reservable_online?
  end

  def create?
    return false if record.rdv.revoked?

    (record.rdv.collectif? && record.rdv.reservable_online?) && rdvs_user_belongs_to_user_or_relatives?
  end

  class Scope < Scope
    alias current_user pundit_user

    def resolve
      scope
        .where(user_id: current_user.available_users_for_rdv.pluck(:id))
    end
  end
end
