class Admin::Organisations::ConfigurationsController < AgentAuthController
  before_action :set_organisation, only: [:show]

  # Cette action permet à des apps externes qui sont intégrées via OAuth de fournir un lien vers la configuration sans avoir
  # à connaitre l'id de l'organisation de l'agent
  def index
    @organisations = policy_scope(current_agent.admin_orgs, policy_scope_class: Agent::OrganisationPolicy::Scope)

    if @organisations.count == 1
      redirect_to admin_organisation_configuration_path(@organisations.first)
    else
      render :index, layout: "application"
    end
  end

  def show
    authorize(@organisation, :edit?, policy_class: Agent::OrganisationPolicy)

    @agents_scope = current_organisation.agents.active

    @motif_names = current_organisation.motifs.active.pluck(:name).uniq
    @lieu_names = current_organisation.lieux.enabled.pluck(:name)
  end

  private

  def pundit_user
    AgentContext.new(current_agent)
  end
end
