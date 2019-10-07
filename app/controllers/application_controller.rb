class ApplicationController < ActionController::Base
  include Pundit
  protect_from_forgery
  before_action :configure_permitted_parameters, if: :devise_controller?
  before_action :store_user_location!, if: :storable_location?

  def after_sign_in_path_for(resource)
    path = if resource.class == Pro
             current_pro.complete? ? authenticated_pro_root_path : new_pros_full_subscription_path
           elsif resource.class == User
             stored_location_for(resource) || authenticated_user_root_path
           end
    path
  end

  def after_invite_path_for(inviter, invitee)
    if invitee.is_a? Pro
      pros_path
    elsif invitee.is_a? User
      organisation_users_path(inviter.organisation)
    end
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

  def authenticate_inviter!
    authenticate_pro!(force: true)
  end

  def configure_permitted_parameters
    if resource_class == Pro
      devise_parameter_sanitizer.permit(:invite, keys: [:email, :role, :service_id])
      devise_parameter_sanitizer.permit(:accept_invitation, keys: [:first_name, :last_name])
      devise_parameter_sanitizer.permit(:account_update, keys: [:first_name, :last_name, :service_id])
    elsif resource_class == User
      devise_parameter_sanitizer.permit(:invite, keys: [:email, :first_name, :last_name, :address, :phone_number, :birth_date])
      devise_parameter_sanitizer.permit(:sign_up, keys: [:first_name, :last_name, :email, :password])
      devise_parameter_sanitizer.permit(:account_update, keys: [:first_name, :last_name, :birth_date])
    end
  end

  def storable_location?
    request.get? && is_navigational_format? && !devise_controller? && !request.xhr?
  end

  def store_user_location!
    # :user is the scope we are authenticating
    store_location_for(:user, request.fullpath)
  end
end
