# frozen_string_literal: true

class Api::V1::UserProfilesController < Api::V1::AgentAuthBaseController
  def create
    user_profile = UserProfile.new(user_profile_params)
    authorize(user_profile)
    user_profile.save!
    render_record user_profile
  rescue ArgumentError => e
    render_error :unprocessable_entity, { success: false, errors: {}, error_messages: [e] }
  end

  def destroy
    user_profile = UserProfile.find_by!(user_profile_params)
    authorize(user_profile)

    organisation = user_profile.organisation
    user = user_profile.user

    if user.can_be_removed_from_organisation?(organisation)
      user.remove_from_organisation!(organisation)
      head :no_content
    else
      render_error :unprocessable_entity, {
        success: false, errors: {},
        error_messages: [I18n.t("users.can_not_delete_because_has_future_rdvs")],
      }
    end
  end

  private

  def user_profile_params
    params.permit(:organisation_id, :user_id, :logement, :notes)
  end
end
