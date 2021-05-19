# frozen_string_literal: true

class Api::V1::UserProfilesController < Api::V1::BaseController
  PERMITTED_PARAMS = %i[organisation_id user_id logement notes].freeze

  def create
    user_profile = UserProfile.new(user_profile_params)
    authorize(user_profile)
    if user_profile.save
      render json: UserProfileBlueprint.render(user_profile, root: :user_profile)
    else
      render_invalid_resource(user_profile)
    end
  end

  private

  def user_profile_params
    params.permit(*PERMITTED_PARAMS)
  end
end
