class Admin::OrganisationsController < AgentAuthController
  respond_to :html, :json

  before_action :set_organisation, except: :index

  def index
    @organisations_by_territory = policy_scope(current_agent.organisations, policy_scope_class: Agent::OrganisationPolicy::Scope)
      .includes(:territory)
      .ordered_by_name
      .to_a.group_by(&:territory)
    @active_agent_preferences_menu_item = :organisations
    render layout: "application_agent_config"
  end

  def show
    authorize(@organisation, policy_class: Agent::OrganisationPolicy)
  end

  def edit
    authorize(@organisation, policy_class: Agent::OrganisationPolicy)
  end

  def update
    authorize(@organisation, policy_class: Agent::OrganisationPolicy)

    if @organisation.update(organisation_params)
      flash[:success] = "Les informations de contact ont été modifiées"
      redirect_to admin_organisation_path(@organisation)
    else
      render :edit
    end
  end

  private

  def current_organisation
    # overrides AgentAuthController's because here it's params[:id]
    if params[:id].present?
      current_agent.organisations.find(params[:id])
    else
      current_agent.organisations.first # necessary for pundit but should not
    end
  end

  def organisation_params
    params.require(:organisation).permit(:name, :horaires, :phone_number, :website, :email)
  end

  def pundit_user
    current_agent
  end
end
