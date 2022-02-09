# frozen_string_literal: true

module InvitableConcern
  extend ActiveSupport::Concern

  included do
    before_action :store_token_in_session, if: -> { params[:invitation_token].present? }
    before_action :redirect_if_invalid_invitation, if: -> { params[:invitation_token].present? }
    before_action :redirect_if_logged_in_user_is_not_invited_user, if: -> { params[:invitation_token].present? }
  end

  private

  def store_token_in_session
    session[:invitation_token] = params[:invitation_token]
  end

  def redirect_if_invalid_invitation
    return if invited_user.present?

    session.delete(:invitation_token)
    flash[:error] = t("devise.invitations.invitation_token_invalid")
    redirect_to root_path
  end

  def redirect_if_logged_in_user_is_not_invited_user
    return if current_user.blank?
    return if invited_user == current_user

    session.delete(:invitation_token)
    flash[:error] = t("devise.invitations.current_user_mismatch")
    redirect_to root_path
  end

  def invitation?
    invited_user.present?
  end

  def invited_user
    # rubocop:disable Rails/DynamicFindBy
    # find_by_invitation_token is a method added by the devise_invitable gem
    @invited_user ||= User.find_by_invitation_token(session[:invitation_token], true)
    # rubocop:enable Rails/DynamicFindBy
  end
end
