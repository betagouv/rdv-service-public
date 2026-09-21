class Api::Rdvinsertion::UserProfilesController < Api::Rdvinsertion::AgentAuthBaseController
  before_action :set_user, :set_organisations, only: %i[create_many]

  def create_many
    @organisations.each { |organisation| UserProfile.find_or_create_by!(user: @user, organisation: organisation) }
    head :ok
  end

  private

  def set_organisations
    @organisations = Organisation.where(id: user_profiles_params[:organisation_ids]).where(verticale: "rdv_insertion")
  end

  # Sur rdv-insertion, un agent peut:
  # - Prendre un usager de son territoire et le rattacher à son organisation
  # - Prendre un usager de son organisation et le rattacher à une autre organisation de son territoire
  # On vérifie donc que l'usager appartient à un territoire de l'agent.
  def set_user
    @user = users_in_agent_territories.find(user_profiles_params[:user_id])
  rescue ActiveRecord::RecordNotFound
    render_error :not_found, not_found: :user
  end

  def users_in_agent_territories
    User.joins(:organisations).where(
      organisations: {
        territory_id: current_agent.territories_through_organisations.select(:id),
        verticale: "rdv_insertion",
      }
    )
  end

  def user_profiles_params
    params.permit(:user_id, organisation_ids: [])
  end
end
