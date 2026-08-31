class UserAuthController < ApplicationController
  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  before_action :authenticate_user!
  before_action :set_paper_trail_whodunnit

  after_action :verify_authorized, except: :index
  after_action :verify_policy_scoped, only: :index

  private

  def user_for_paper_trail
    current_user.name_for_paper_trail
  end

  def user_not_authorized(exception)
    policy_name = exception.policy.class.to_s.underscore
    flash[:error] = t "#{policy_name}.#{exception.query}", scope: "pundit", default: :default
    redirect_to authenticated_user_root_path
  end

  def authenticated_user_root_path
    current_user.signed_in_with_restricted_auth_token? ? root_path : users_rdvs_path
  end
end
