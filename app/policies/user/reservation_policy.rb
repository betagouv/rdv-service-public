# frozen_string_literal: true

class User::ReservationPolicy < ApplicationPolicy
  alias current_user pundit_user

  def new?
    if record.collectif? && record.reservable_online?
      Pundit.policy(current_user, RdvsUser.new).new?
    else
      Pundit.policy(current_user, rdv).new?
    end
  end
end
