class ApplicationController < ActionController::Base
  include Pundit
  protect_from_forgery
  before_action :configure_permitted_parameters, if: :devise_controller?

  def after_sign_in_path_for(_resource)
    path =
      if !current_pro.complete?
        new_pros_full_subscription_path
      else
        authenticated_root_path
      end
    path
  end

  def after_invite_path_for(inviter, _invitee)
    organisation_pros_path(inviter.organisation)
  end

  def respond_modal_with(*args, &blk)
    options = args.extract_options!
    options[:responder] = ModalResponder
    respond_with *args, options, &blk
  end

  def respond_right_bar_with(*args, &blk)
    options = args.extract_options!
    options[:responder] = RightBarResponder
    respond_with *args, options, &blk
  end

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:invite, keys: [:email, :role])
    devise_parameter_sanitizer.permit(:accept_invitation, keys: [:first_name, :last_name])
    devise_parameter_sanitizer.permit(:account_update, keys: [:first_name, :last_name])
  end
end
