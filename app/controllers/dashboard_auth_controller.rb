class DashboardAuthController < ApplicationController
  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  before_action :authenticate_pro!

  after_action :verify_authorized, except: :index
  after_action :verify_policy_scoped, only: :index

  private

  def user_not_authorized(exception)
    policy_name = exception.policy.class.to_s.underscore

    flash[:error] = t "#{policy_name}.#{exception.query}", scope: "pundit", default: :default
    redirect_to(request.referrer || authenticated_root_path)
  end
end