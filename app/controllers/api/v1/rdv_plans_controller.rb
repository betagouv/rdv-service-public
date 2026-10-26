class Api::V1::RdvPlansController < Api::V1::AgentAuthBaseController
  def create
    rdv_plan = RdvPlan.transaction do
      user_params = params.require(:user)

      user = if user_params[:external_id].present?
               upsert_user(user_params)
             else
               find_or_build_user(user_params)
             end

      user.save!
      RdvPlan.create!(
        rdv_agent: current_agent,
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
    rdv_plan = policy_scope(RdvPlan, policy_scope_class: Agent::RdvPlanPolicy::Scope).includes(rdv: :organisation).find(params[:id])

    render_record rdv_plan
  end

  private

  def pundit_user
    current_agent
  end

  def upsert_user(user_params)
    external_reference = ExternalReference.where(item_type: "User", oauth_application: doorkeeper_token&.application).find_by(user_params.permit[:external_id])

    user = external_reference&.item

    if user && agent_has_access_to_user?(user)
      user.assign_attributes(permitted_user_params(user_params))

    else
      user = build_user(user_params)
    end

    if external_reference.nil?
      user.external_references.build(
        oauth_application: doorkeeper_token&.application,
        external_id: user_params[:external_id]
      )
    end

    user
  end

  def permitted_user_params(user_params)
    user_params.permit(:first_name, :last_name, :email, :address, :phone_number, :birth_date)
  end

  def find_or_build_user(user_params)
    find_user(user_params) || build_user(user_params)
  end

  def build_user(user_params)
    User.new(permitted_user_params(user_params))
  end

  def find_user(user_params)
    if user_params.permit(:id).present?
      user = User.find(user_params[:id])

      raise Pundit::NotAuthorizedError unless agent_has_access_to_user?(user)

      user
    elsif user_params[:email].present?
      user = User.find_by(user_params.permit(:email))

      return nil unless user

      user if agent_has_access_to_user?(user)
    end
  end

  # La présence de current_organisation dans Agent::UserPolicy nous empêche de réutiliser la policy directement ici
  def agent_has_access_to_user?(user)
    user.organisation_ids.intersect?(current_agent.organisation_ids) || RdvPlan.where(planning_agent: current_agent, user: user).any?
  end
end
