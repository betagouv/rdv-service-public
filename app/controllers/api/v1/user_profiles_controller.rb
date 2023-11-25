class Api::V1::UserProfilesController < Api::V1::AgentAuthBaseController
  def create
    if user_profiles_params[:organisation_ids].present?
      create_user_profiles
    else
      create_user_profile(user_profiles_params)
    end
    user = User.find(user_profiles_params[:user_id])
    render_record user, agent_context: pundit_user
  end

  def destroy
    user_profile = UserProfile.find_by!(user_profile_params)
    authorize(user_profile)

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

  def create_user_profiles
    user_profiles_params[:organisation_ids].each do |organisation_id|
      create_user_profile(user_profiles_params.except(:organisation_ids).merge(organisation_id: organisation_id))
    end
  end

  def create_user_profile(user_profile_attributes)
    user_profile = UserProfile.new(user_profile_attributes)
    authorize(user_profile)
    user_profile.save
  end

  def user_profiles_params
    params.permit(:organisation_id, :user_id, :logement, :notes, organisation_ids: []).to_h.symbolize_keys
  end
end
