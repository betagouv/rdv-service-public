class Api::V1::UserProfilesController < Api::V1::AgentAuthBaseController
  before_action :validate_params, only: :upsert_many

  def create
    user_profile = UserProfile.new(user_profile_params)
    authorize(user_profile)
    user_profile.save!
    render_record user_profile
  rescue ArgumentError => e
    render_error :unprocessable_entity, { success: false, errors: {}, error_messages: [e] }
  end

  def upsert_many
    create_user_profiles
    user = User.find(user_profiles_params[:user_id])
    render_record user, agent_context: pundit_user
  rescue StandardError => e
    render_error :unprocessable_entity, { success: false, errors: {}, error_messages: [e] }
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
      user_profile =
        UserProfile.find_or_initialize_by(user_profiles_params.except(:organisation_ids).merge(organisation_id: organisation_id))
      begin
        authorize(user_profile)
        user_profile.save
      rescue Pundit::NotAuthorizedError
        next # we don't want to block the whole request if some organisations are not authorized
      end
    end
  end

  def user_profile_params
    params.permit(:organisation_id, :user_id, :logement, :notes)
  end

  def user_profiles_params
    params.permit(:user_id, :logement, :notes, organisation_ids: []).to_h.symbolize_keys
  end
end
