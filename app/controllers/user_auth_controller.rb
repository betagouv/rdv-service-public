# frozen_string_literal: true

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

  def authorize(record)
    super([:user, record])
  end

  def current_user
    super || invited_user
  end

  def current_user_set?
    current_user.present?
  end

  def policy_scope(clasz)
    super([:user, clasz])
  end

  def user_not_authorized(exception)
    policy_name = exception.policy.class.to_s.underscore
    flash[:error] = t "#{policy_name}.#{exception.query}", scope: "pundit", default: :default
    redirect_to(request.referer || authenticated_user_root_path)
  end
end
