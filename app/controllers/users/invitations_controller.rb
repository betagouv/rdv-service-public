# frozen_string_literal: true

class Users::InvitationsController < Devise::InvitationsController
  layout "user_registration"
  # rubocop:disable Rails/LexicallyScopedActionFilter
  before_action :delete_token_from_session, only: [:update]
  # rubocop:enable Rails/LexicallyScopedActionFilter

  include CanHaveRdvWizardContext

  def invitation; end

  def resource_from_invitation_token
    # Short token for emailless users is only numerical + uppercase letters
    params[:invitation_token] = params[:invitation_token].upcase if params[:invitation_token]&.length == 8

    # if the token is invalid we remove it from the session
    delete_token_from_session unless resource_class.find_by_invitation_token(params[:invitation_token], true)
    super
  end

  def after_sign_out_path_for(resource)
    return invitations_landing_url if request.referer&.end_with?("/invitation")

    super
  end

  def after_accept_path_for(resource)
    return session[:user_return_to] if session[:user_return_to].present?

    super
  end

  def edit
    # Reuse prefilled params from the invitation email
    resource.assign_attributes(update_resource_params)
    super
  end

  private

  def delete_token_from_session
    session.delete(:invitation_token)
  end
end
