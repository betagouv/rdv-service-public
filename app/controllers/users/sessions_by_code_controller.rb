class Users::SessionsByCodeController < ApplicationController
  attr_reader :email

  layout "application_narrow"

  include CanHaveRdvWizardContext

  def new
    @email = params[:email]
    return redirect_to(new_user_session_path) if @email.blank?

    user = User.find_by(email:)
    agent = Agent.find_by(email:)
    redirect_to new_agent_session_path(agent: { email: }) if !user && agent

    @existing_login_code = LoginCode.most_recent_usable_for(email:)&.tap(&:safe_to_display!)
  end

  def create
    @email = params[:login_code][:email]
    submitted_login_code = params[:login_code][:code]
    matching_login_code = LoginCode.where(email:, code: submitted_login_code).where("created_at > ?", 24.hours.ago).first

    if matching_login_code&.usable?
      user = User.find_by!(email:)
      user.confirm
      sign_in(:user, user)
      matching_login_code.update!(used_at: Time.zone.now)
      flash[:success] = "Connexion réussie"
      redirect_to after_sign_in_path_for(user)
    elsif LoginCode.where(email:).usable.any?
      flash[:error] = "Veuillez renseigner le dernier code qui vous a été envoyé par email, ou attendre quelques instants de le recevoir"
      @existing_login_code = LoginCode.most_recent_usable_for(email:)&.tap(&:safe_to_display!)
      render :new
    elsif matching_login_code&.used?
      flash[:error] = "Code déjà utilisé, veuillez en demander un nouveau"
      redirect_to new_users_sessions_by_code_path(email:)
    elsif matching_login_code&.expired?
      flash[:error] = "Code expiré, veuillez en demander un nouveau"
      redirect_to new_users_sessions_by_code_path(email:)
    else
      flash[:error] = "Code invalide"
      redirect_to new_users_sessions_by_code_path(email:)
    end
  end

  private

  def storable_location? = false
end
