class Users::LoginByCodeController < ApplicationController
  layout "application_narrow"

  def code_form
    @email = params[:email].presence
    redirect_to new_user_session_path unless @email
  end

  def submit_login_code
    email = params.require(:email)
    submitted_login_code = params[:login_code]

    if submitted_login_code == UserLoginCode.code_for(email)
      self.current_user_email = email
      users = User.where(email:).or(User.where(notification_email: email)).to_a
      case users.size
      when 0
        flash[:error] = "Il n'existe aucune fiche usager avec l'email #{email}"
        redirect_to users_code_form_path(email:)
      when 1
        user = users.first
        sign_in(:user, user)
        flash[:success] = "Connexion réussie"
        redirect_to after_sign_in_path_for(user)
      else
        redirect_to users_choix_fiche_path
      end
    else
      flash[:error] = "Code invalide"
      redirect_to users_code_form_path(email:)
    end
  end

  def choix_fiche
    redirect_to root_path and return unless current_user_email

    @email = current_user_email
    @fiches_usagers = User.where(email: @email).or(User.where(notification_email: @email)).to_a
  end

  def submit_choix_fiche
    redirect_to root_path and return unless current_user_email

    user = User.find(params[:user_id])
    if user.email_or_notification_email == current_user_email
      user.confirm
      sign_in(:user, user)
      redirect_to after_sign_in_path_for(user)
    else
      flash[:error] = "Impossible de se connecter avec cette fiche : elle ne porte pas votre e-mail"
      redirect_to users_choix_fiche_path
    end
  end

  private

  def storable_location?
    false
  end
end
