# frozen_string_literal: true

class Api::V1::InvitationsController < Api::V1::AgentAuthBaseController
  before_action :set_user

  def show
    authorize(@user)
    render_record(@user)
  end

  private

  def set_user
    # rubocop:disable Rails/DynamicFindBy
    # find_by_invitation_token is a method added by the devise_invitable gem
    @user = User.find_by_invitation_token(params[:token], true)
    # rubocop:enable Rails/DynamicFindBy

    render_error :not_found, not_found: :user unless @user
  end
end
