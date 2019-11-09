class UserAuthController < ApplicationController
  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  layout 'application_user'
  before_action :authenticate_user!

  after_action :verify_authorized, except: :index
  after_action :verify_policy_scoped, only: :index

  private

  def authorize(record)
    super([:user, record])
  end

  def policy_scope(clasz)
    super([:user, clasz])
  end

  def user_not_authorized(exception)
    policy_name = exception.policy.class.to_s.underscore
    flash[:error] = t "#{policy_name}.#{exception.query}", scope: "pundit", default: :default
    redirect_to(request.referrer || authenticated_user_root_path)
  end
end
