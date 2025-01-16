class Api::V1::RdvPlansController < Api::V1::AgentAuthBaseController
  def create
    rdv_plan = RdvPlan.transaction do
      user_params = params.require(:user)

      user = find_or_build_user(user_params)

      RdvPlan.create!(
        planning_agent: current_agent,
        user: user,
        return_url: params[:return_url]
      )
    end
    render json: RdvPlanBlueprint.render(rdv_plan, root: "rdv_plan"), status: :created
  end

  def show
    rdv_plan = policy_scope(RdvPlan, policy_scope_class: Agent::RdvPlanPolicy::Scope).find(params[:id])

    render_record rdv_plan
  end

  private

  def find_or_build_user(user_params)
    find_user(user_params) || build_user(user_params)
  end

  def build_user(user_params)
    User.new(user_params.permit(:first_name, :last_name, :email, :address, :phone_number, :birth_date))
      .tap(&:skip_confirmation_notification!)
  end

  def find_user(user_params)
    if user_params.permit(:id).present?

      # Peut-être qu'on pourrait utiliser Agent::UserPolicy::TerritoryScope ici si on le
      # refactore pour ne pas utiliser de current organisation
      profile = UserProfile.joins(:organisation).find_by(
        organisations: { territory_id: current_agent.agent_territorial_access_rights.select(:territory_id) },
        user_id: user_params[:id]
      )

      if profile
        # TODO: gérer la mise à jour d'un usager en fonction des autres params
        profile.user
      else
        raise Pundit::NotAuthorizedError
      end

    elsif user_params[:email].present?
      User.find_by(user_params.permit(:email))
    end
  end
end
