class Users::SessionsByCodeController < ApplicationController
  attr_reader :email

  layout "application_narrow"

  include CanHaveRdvWizardContext

  def new
    @email = params[:email]
    return redirect_to(new_user_session_path) if @email.blank?

    return redirect_to(new_user_session_path, flash: { error: "Veuillez recommencer votre connexion" }) unless User.exists?(email:)

    @existing_login_code = LoginCode.most_recent_usable_for(email:)&.tap(&:safe_to_display!)
  end

  # rubocop:disable Metrics/PerceivedComplexity
  def create
    @email = params[:login_code][:email]
    submitted_login_code = params[:login_code][:code]
    matching_login_code = LoginCode.where(email:, code: submitted_login_code).where("created_at > ?", 24.hours.ago).first

    if matching_login_code&.usable?
      user = User.find_by!(email:)
      user.confirm
      sign_in(:user, user)
      matching_login_code.update!(used_at: Time.zone.now)
      redirect_to after_sign_in_path_for(user), flash: { success: "Connexion réussie" }
    elsif LoginCode.where(email:).usable.any?
      @existing_login_code = LoginCode.most_recent_usable_for(email:)&.tap(&:safe_to_display!)
      @existing_login_code.errors.add(:base, "Veuillez renseigner le dernier code qui vous a été envoyé par email, ou attendre quelques instants de le recevoir")
      render :new
    else
      flash[:error] =
        if matching_login_code&.used?
          "Code déjà utilisé, veuillez en demander un nouveau"
        elsif matching_login_code&.expired?
          "Code expiré, veuillez en demander un nouveau"
        else
          "Code invalide"
        end
      redirect_to new_users_sessions_by_code_path(email:)
    end
  end
  # rubocop:enable Metrics/PerceivedComplexity

  private

  def storable_location? = false
end
