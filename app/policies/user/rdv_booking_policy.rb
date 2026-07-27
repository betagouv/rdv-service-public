class User::RdvBookingPolicy < ApplicationPolicy
  alias current_user pundit_user
  alias rdv_booking_form record

  def new?
    return false unless motif_bookable?

    if rdv.collectif?
      !rdv.revoked?
    else
      rdv.users == [current_user] # dans le GET new le rdv est instancié avec current_user
    end
  end

  def create?
    !rdv.revoked? && motif_bookable? && only_current_user_or_relatives_are_selected?
  end

  private

  def rdv = rdv_booking_form.rdv
  def motif_bookable? = rdv.motif.bookable_by_everyone_or_bookable_by_invited_users?

  def only_current_user_or_relatives_are_selected?
    rdv_booking_form.selected_users_params.all? do |param|
      param.current_user? ||
        param.new_relative? ||
        (param.existing_relative? && current_user_or_relatives_ids.include?(param.id.to_i))
    end
  end

  def current_user_or_relatives_ids
    @current_user_or_relatives_ids ||= current_user.available_users_for_rdv.pluck(:id)
  end
end
