class User::RdvBookingPolicy < ApplicationPolicy
  alias current_user pundit_user
  alias rdv_booking_form record

  def new?
    !rdv.revoked? && motif_bookable? && (rdv.collectif? || rdv.users == [current_user])
  end

  def create?
    !rdv.revoked? && motif_bookable? && only_current_user_or_relatives_are_selected?
  end

  private

  def rdv = rdv_booking_form.rdv
  def motif_bookable? = rdv.motif.bookable_by_everyone_or_bookable_by_invited_users?

  def only_current_user_or_relatives_are_selected?
    rdv_booking_form.selected_users.all? do |user|
      case user
      when "current_user", /\Anew_relative_(\d+)\z/
        true
      when /\Aexisting_relative_(\d+)\z/
        current_user_or_relatives_ids.include?(Regexp.last_match(1).to_i)
      else
        false
      end
    end
  end

  def current_user_or_relatives_ids
    @current_user_or_relatives_ids ||= current_user.available_users_for_rdv.pluck(:id)
  end
end
