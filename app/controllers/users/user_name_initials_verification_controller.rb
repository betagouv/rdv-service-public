class Users::UserNameInitialsVerificationController < UserAuthController
  layout "application_narrow"

  skip_after_action :verify_authorized

  include TokenInvitable

  def new; end

  def create
    if first_three_letters_matching?
      set_user_name_initials_verified
      redirect_to after_success_redirect_path
    else
      flash.now[:error] = I18n.t("users.user_name_initials_mismatch")
      render :new
    end
  end

  private

  def letter_params
    params.permit(:letter0, :letter1, :letter2)
  end

  def after_success_redirect_path
    return session.delete(:return_to_after_verification) if session[:return_to_after_verification]
    return users_rdv_path(invitation.rdv) if invitation&.rdv

    root_path
  end

  def first_three_letters
    letter_params.to_h.values.join.strip
  end

  def first_three_letters_matching?
    user_name_initials.upcase == first_three_letters.upcase
  end

  def user_name_initials
    current_user.last_name.gsub(/\s+/, "").first(3)
  end
end
