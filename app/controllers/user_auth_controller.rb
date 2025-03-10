class UserAuthController < ApplicationController
  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  before_action :authenticate_user!
  before_action :set_paper_trail_whodunnit

  after_action :verify_authorized, except: :index
  after_action :verify_policy_scoped, only: :index

  private

  def user_for_paper_trail
    if current_super_admin.present?
      current_super_admin.name_for_paper_trail(impersonated: current_user)
    else
      current_user.name_for_paper_trail
    end
  end

  def user_not_authorized(exception)
    policy_name = exception.policy.class.to_s.underscore
    flash[:error] = t "#{policy_name}.#{exception.query}", scope: "pundit", default: :default
    redirect_to authenticated_user_root_path
  end

  def authenticated_user_root_path
    current_user.signed_in_with_invitation_token? ? root_path : users_rdvs_path
  end

  def should_verify_user_name_initials?
    current_user.signed_in_with_invitation_token? && !cookies.encrypted[user_name_initials_cookie_name]
  end

  def verify_user_name_initials
    return unless should_verify_user_name_initials?

    session[:return_to_after_verification] = request.fullpath
    redirect_to new_users_user_name_initials_verification_path
  end

  # Cette méthode est appelée quand l'usager vérifie ses initiales au moment d'une première "connexion"
  # ou s'il fait une action d'écriture sur une participation (dont une création de rdv)
  def set_user_name_initials_verified
    cookies.encrypted[user_name_initials_cookie_name] = {
      value: true, expires: 10.minutes.from_now,
    }
  end

  def user_name_initials_cookie_name
    :"user_name_initials_verified_#{current_user.id}"
  end
end
