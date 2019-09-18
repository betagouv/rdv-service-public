class ApplicationController < ActionController::Base
  include Pundit
  protect_from_forgery
  before_action :configure_permitted_parameters, if: :devise_controller?

  def after_sign_in_path_for(resource)
    path = if resource == Pro
            current_pro.complete? ? authenticated_pro_root_path : new_pros_full_subscription_path
          elsif resource == User
            authenticated_user_root_path
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
    if resource_class == Pro
      devise_parameter_sanitizer.permit(:invite, keys: [:email, :role, :service_id])
      devise_parameter_sanitizer.permit(:accept_invitation, keys: [:first_name, :last_name])
      devise_parameter_sanitizer.permit(:account_update, keys: [:first_name, :last_name, :service_id])
    elsif resource_class == User
      devise_parameter_sanitizer.permit(:sign_up, keys: [:first_name, :last_name, :email, :password])
    end
  end
end
