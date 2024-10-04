class Api::V1::UserProfilesController < Api::V1::AgentAuthBaseController
  def create
    user_profile = UserProfile.new(user_profile_params)
    authorize(user_profile, policy_class: Agent::UserProfilePolicy)
    user_profile.save!
    render_record user_profile
  rescue ArgumentError => e
    render_error :unprocessable_entity, { success: false, errors: {}, error_messages: [e] }
  end

  def destroy
    user_profile = UserProfile.find_by!(user_profile_params)
    authorize(user_profile, policy_class: Agent::UserProfilePolicy)

    organisation = user_profile.organisation
    user = user_profile.user

    if user.can_be_soft_deleted_from_organisation?(organisation)
      user.soft_delete(organisation)
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
    params.permit(:organisation_id, :user_id)
  end
end
