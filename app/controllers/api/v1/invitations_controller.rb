# frozen_string_literal: true

class Api::V1::InvitationsController < Api::V1::AgentAuthBaseController
  before_action :set_user_compatibility, only: %i[show]
  before_action :set_user, only: %i[rdv_invitation_token]

  def show
    # Todo remove this method after rdvi migrated to the new endpoint
    authorize(@user)
    render_record(@user)
  end

  def rdv_invitation_token
    authorize(@user)
    assign_rdv_invitation_token if @user.rdv_invitation_token.nil?
    render json: { invitation_token: @user.rdv_invitation_token }
  end

  private

  def assign_rdv_invitation_token
    @user.assign_rdv_invitation_token
    @user.invited_through = "external"
    @user.save!
  end

  def set_user_compatibility
    # Todo remove this method after rdvi migrated to the new endpoint
    @user = User.find_by(rdv_invitation_token: params[:token])

    render_error :not_found, not_found: :user unless @user
  end

  def set_user
    @user = User.find_by(params[:user_id])
    authorize(@user)
  rescue ActiveRecord::RecordNotFound
    render_error :not_found, not_found: :user
  end
end
