class Api::V1::RdvPlansController < Api::V1::AgentAuthBaseController
  def create
    rdv_plan = RdvPlan.transaction do
      user_params = params.require(:user)

      user = find_or_build_user(user_params)

      user.save!
      RdvPlan.create!(
        planning_agent: current_agent,
        user: user,
        oauth_application: doorkeeper_token&.application,
        return_url: params[:return_url],
        dossier_url: params[:dossier_url]
      )
    end
    render json: RdvPlanBlueprint.render(rdv_plan, root: "rdv_plan"), status: :created
  end

  def show
    rdv_plan = policy_scope(RdvPlan, policy_scope_class: Agent::RdvPlanPolicy::Scope).find(params[:id])

    render_record rdv_plan
  end

  private

  def pundit_user
    current_agent
  end

  def find_or_build_user(user_params)
    find_user(user_params) || build_user(user_params)
  end

  def build_user(user_params)
    user = User.new(user_params.permit(:first_name, :last_name, :address, :phone_number, :birth_date))
    # TODO: mettre un commentaire pour expliquer pourquoi cette ligne nous rend triste
    user.notification_email = user_params[:email]
    user.skip_confirmation_notification!
    user
  end

  def find_user(user_params)
    if user_params.permit(:id).present?

      user = User.find(user_params[:id])

      # La présence de current_organisation dans Agent::UserPolicy nous empêche de réutiliser la policy directement ici
      unless user.organisation_ids.intersect?(current_agent.organisation_ids) || RdvPlan.where(planning_agent: current_agent, user: user).any?
        raise Pundit::NotAuthorizedError
      end

      user
    elsif user_params[:email].present?
      User.find_by(user_params.permit(:email))
    end
  end
end
