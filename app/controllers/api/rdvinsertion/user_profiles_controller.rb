class Api::Rdvinsertion::UserProfilesController < Api::V1::AgentAuthBaseController
  before_action :set_user, :set_organisations, only: %i[create_many]

  def create_many
    @organisations.each { |organisation| UserProfile.find_or_create_by!(user: @user, organisation: organisation) }
    head :ok
  end

  private

  def set_organisations
    @organisations = Organisation.where(id: user_profiles_params[:organisation_ids]).where(verticale: "rdv_insertion")
  end

  def set_user
    @user = User.find(user_profiles_params[:user_id])
  rescue ActiveRecord::RecordNotFound
    render_error :not_found, not_found: :user
  end

  def user_profiles_params
    params.permit(:user_id, organisation_ids: [])
  end
end
