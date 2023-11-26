class Api::V1::UserProfilesController < Api::V1::AgentAuthBaseController
  before_action :validate_params, only: :create_many

  def create
    user_profile = UserProfile.new(user_profile_params)
    authorize(user_profile)
    user_profile.save!
    render_record user_profile
  rescue ArgumentError => e
    render_error :unprocessable_entity, { success: false, errors: {}, error_messages: [e] }
  end

  def create_many
    if @params_validation_errors.blank?
      create_user_profiles
      user = User.find(user_profiles_params[:user_id])
      render_record user, agent_context: pundit_user
    else
      render json: { success: false, errors: {}, error_messages: @params_validation_errors }, status: :unprocessable_entity
    end
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
        UserProfile.new(user_profiles_params.except(:organisation_ids).merge(organisation_id: organisation_id))
      begin
        authorize(user_profile)
        user_profile.save
      rescue Pundit::NotAuthorizedError
        next # we don't want to block the whole request if some organisations are authorized
      end
    end
  end

  def validate_params
    @params_validation_errors = []

    validate_organisation_ids
    validate_user_id
  end

  def validate_organisation_ids
    return if user_profiles_params[:organisation_ids].present?

    @params_validation_errors << I18n.t("user_profiles.create_many.no_organisation_ids")
  end

  def validate_user_id
    if user_profiles_params[:user_id].blank?
      @params_validation_errors << I18n.t("user_profiles.create_many.no_user_id")
    elsif !User.exists?(user_profiles_params[:user_id])
      @params_validation_errors << I18n.t("user_profiles.create_many.unknown_user_id")
    end
  end

  def user_profile_params
    params.permit(:organisation_id, :user_id, :logement, :notes)
  end

  def user_profiles_params
    params.permit(:user_id, :logement, :notes, organisation_ids: []).to_h.symbolize_keys
  end
end
