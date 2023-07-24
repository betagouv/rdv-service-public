# frozen_string_literal: true

# Todo remove this class after rdvi migrated to the new endpoint
class Api::V1::InvitationsController < Api::V1::AgentAuthBaseController
  before_action :set_user

  def show
    authorize(@user)
    render_record(@user)
  end

  private

  def set_user
    @user = User.find_by(rdv_invitation_token: params[:token])

    render_error :not_found, not_found: :user unless @user
  end
end
