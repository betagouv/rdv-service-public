# frozen_string_literal: true

class ApplicationController < ActionController::Base
  include Pundit
  protect_from_forgery
  before_action :configure_permitted_parameters, if: :devise_controller?
  before_action :store_user_location!, if: :storable_location?
  before_action :set_sentry_context

  def after_sign_in_path_for(resource)
    if resource.instance_of?(Agent)
      authenticated_agent_root_path
    elsif resource.instance_of?(User)
      stored_location_for(resource) || authenticated_user_root_path
    end
  end

  def after_sign_out_path_for(resource)
    return "https://#{ENV['FRANCECONNECT_HOST']}/api/v1/logout" \
      if @connected_with_franceconnect

    super
  end

  def respond_modal_with(*args, &blk)
    options = args.extract_options!
    options[:responder] = ModalResponder
    respond_with(*args, options, &blk)
  end

  def demo? # replace with rdv_solidarites_instance_name
    ENV["HOST"]&.match(/demo/)
  end
  helper_method :demo?

  protected

  def store_invitation_token_in_session_if_present
    return if params[:invitation_token].blank?

    session[:invitation_token] = params[:invitation_token]
  end

  def set_sentry_context
    Sentry.set_user(sentry_user)
  end

  def sentry_user
    user = current_agent || current_user
    {
      id: user&.id,
      role: user&.class&.name || "Guest",
      email: user&.email
    }.compact
  end

  def authenticate_inviter!
    authenticate_agent!(force: true)
  end

  def configure_permitted_parameters
    if resource_class == Agent
      devise_parameter_sanitizer.permit(:invite, keys: [:email, :service_id, { roles_attributes: %i[level organisation_id] }])
      devise_parameter_sanitizer.permit(:accept_invitation, keys: %i[first_name last_name])
      devise_parameter_sanitizer.permit(:account_update, keys: %i[first_name last_name service_id])
    elsif resource_class == User
      devise_parameter_sanitizer.permit(:sign_up, keys: %i[first_name last_name email phone_number password])
      devise_parameter_sanitizer.permit(:invite, keys: %i[email first_name last_name address phone_number birth_date])
      # params for accept_invitation may be passed from the signup to the invitation via the invitation_instructions email.
      devise_parameter_sanitizer.permit(:accept_invitation, keys: %i[first_name last_name email phone_number password])
    end
  end

  def storable_location?
    request.get? && is_navigational_format? && !devise_controller? && !request.xhr? && request.fullpath != root_path
  end

  def store_user_location!
    # :user is the scope we are authenticating
    store_location_for(:user, request.fullpath)
  end

  def add_query_string_params_to_url(url, new_params)
    return url if url.blank?

    # cf https://stackoverflow.com/questions/7785793/add-parameter-to-url
    parsed_uri = URI.parse(url)
    parsed_query_string = URI.decode_www_form(parsed_uri.query || "")
    new_params.each { |k, v| parsed_query_string.append([k, v]) }
    parsed_uri.query = URI.encode_www_form(parsed_query_string)
    parsed_uri.to_s
  end
  helper_method :add_query_string_params_to_url

  def allow_iframe
    response.headers.except! "X-Frame-Options"
  end
end
