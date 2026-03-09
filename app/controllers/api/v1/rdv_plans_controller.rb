class Api::V1::RdvPlansController < Api::V1::AgentAuthBaseController
  def create
    rdv_plan = RdvPlan.transaction do
      user_params = params.require(:user)

      user = find_or_build_user(user_params)

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

  def find_or_build_user(user_params)
    find_user(user_params) || build_user(user_params)
  end

  def build_user(user_params)
    user = User.new(user_params.permit(:first_name, :last_name, :address, :phone_number, :birth_date))

    # Il y a un décalage entre les champs utilisé dans l'api de création de rdv plans, et nos colonnes en base :
    # on demande au client d'envoyer un `email`, mais on l'enregistre dans `notification_email`.
    # C'est à la fois pour garder une api rétrocompatible, et aussi parce qu'on aurait préféré que la colonne notification_email
    # reste juste "email", et que la colonne utilisée pour l'email devise ai un autre nom (peut-être `login_email`, `account_email` ou `devise_email`).
    user.notification_email = user_params[:email]
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
