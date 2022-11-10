# frozen_string_literal: true

class Api::V1::UserProfilesController < Api::V1::AgentAuthBaseController
  def create
    user_profile = UserProfile.new(create_params)
    authorize(user_profile)
    user_profile.save!
    render_record user_profile
  rescue ArgumentError => e
    render_error :unprocessable_entity, { success: false, errors: {}, error_messages: [e] }
  end

  private

  def create_params
    params.permit(:organisation_id, :user_id, :logement, :notes)
  end
end
