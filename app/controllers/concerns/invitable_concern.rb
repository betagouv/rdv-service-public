# frozen_string_literal: true

module InvitableConcern
  extend ActiveSupport::Concern

  included do
    before_action :store_token_in_session_if_present
  end

  private

  def store_token_in_session_if_present
    return if params[:invitation_token].blank?

    session[:invitation_token] = params[:invitation_token]
  end

  def invitation?
    invited_user.present?
  end

  def invited_user
    # rubocop:disable Rails/DynamicFindBy
    # find_by_invitation_token is a method added by the devise_invitable gem
    @invited_user ||= User.find_by_invitation_token(invitation_token, true)
    # rubocop:enable Rails/DynamicFindBy
  end

  def invitation_token
    params[:invitation_token] || session[:invitation_token]
  end
end
