class Users::EmailChangeConfirmationsController < UserAuthController
  layout "application_base"

  before_action :ensure_can_change_email
  before_action { authorize(current_user, :update?, policy_class: User::UserPolicy) }

  def new
    @email = session[:user_new_email_pending_confirmation]
    return redirect_to new_email_change_request_path if @email.blank?

    @existing_login_code = LoginCode.most_recent_usable_for(email: @email)
  end

  def create
    email = login_code_params[:email]
    session[:user_new_email_pending_confirmation] = email
    validator = LoginCodeValidator.new(email:, code: login_code_params[:code])

    if validator.valid?
      valid_login_code = validator.valid_login_code
      current_user.update!(email: valid_login_code.email)
      valid_login_code.update!(used_at: Time.zone.now)
      session.delete(:user_new_email_pending_confirmation)
      redirect_to users_informations_path, flash: { success: "Votre adresse email a été mise à jour." }
    elsif validator.should_redirect_to_code_request?
      redirect_to new_email_change_request_path, flash: { error: validator.error }
    else
      @email = email
      @existing_login_code = LoginCode.most_recent_usable_for(email:)
      @existing_login_code&.errors&.add(:base, validator.error)
      render :new
    end
  end

  private

  def ensure_can_change_email
    return if current_user.can_change_email?

    redirect_to users_informations_path, flash: { error: "Vous ne pouvez pas modifier votre adresse email." }
  end

  def login_code_params
    params.require(:login_code).permit(:email, :code)
  end
end
