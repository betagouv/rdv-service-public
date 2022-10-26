# frozen_string_literal: true

class Api::V1::InvitationsController < Api::V1::AgentAuthBaseController
  def show
    # rubocop:disable Rails/DynamicFindBy
    # find_by_invitation_token is a method added by the devise_invitable gem
    user = User.find_by_invitation_token(params[:token], true)
    # rubocop:enable Rails/DynamicFindBy

    raise ActiveRecord::RecordNotFound unless user

    authorize(user)
    render_record(user)
  end
end
