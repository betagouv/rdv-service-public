class Admin::Territories::OrganisationsController < Admin::Territories::BaseController
  def new
    @organisation = Organisation.new(territory: current_territory)
    authorize(@organisation, policy_class: Agent::OrganisationPolicy)
  end

  def create
    @organisation = Organisation.new(
      agent_roles_attributes: [{ agent: current_agent, access_level: AgentRole::ACCESS_LEVEL_ADMIN }],
      verticale: current_domain.verticale,
      territory: current_territory,
      **params.require(:organisation).permit(:name)
    )
    authorize(@organisation, policy_class: Agent::OrganisationPolicy)

    if @organisation.save
      redirect_to admin_organisation_configuration_path(@organisation),
                  flash: { success: "Organisation enregistrée ! Vous pouvez maintenant lui ajouter des motifs et des lieux de rendez-vous, puis inviter des agents à la rejoindre" }
    else
      render :new
    end
  end

  def index
    @organisations = organisations.joins(:agent_roles).uniq
    @closed_organisations = current_territory.organisations.where.missing(:agent_roles).uniq
  end

  def close
    organisation = Organisation.find(params[:id])
    authorize(organisation, :close?, policy_class: Agent::OrganisationPolicy)

    organisation.agents.where.not(id: current_agent.id).each do |agent|
      agent_removal = AgentRemoval.new(agent, organisation)
      if agent_removal.valid?
        agent_removal.remove!
      end
    end

    if organisation.agents == [current_agent]
      agent_removal = AgentRemoval.new(current_agent, organisation)
      agent_removal.remove! if agent_removal.valid?
    end

    if organisation.reload.agents.empty?
      flash[:success] = "L'organisation a été fermée."
    else
      flash[:error] = "L'organisation n'a pas pu être fermée parce que des agents on encore des rendez-vous à venir dans cette organisation."
    end

    redirect_to admin_territory_organisations_path(organisation.territory)
  end

  def confirm_reopen
    @organisation = Organisation.find(params[:id])
    authorize(@organisation, :create?, policy_class: Agent::OrganisationPolicy)
  end

  def reopen
    @organisation = Organisation.find(params[:id])
    authorize(@organisation, :create?, policy_class: Agent::OrganisationPolicy)
    AgentRole.create!(organisation: @organisation, agent: current_agent, access_level: :admin)
    redirect_to admin_organisation_configuration_path(@organisation),
                flash: { success: "Organisation réouverte ! Vous pouvez inviter des agents à la rejoindre" }
  end

  private

  def organisations
    policy_scope(current_agent.organisations, policy_scope_class: Agent::OrganisationPolicy::Scope)
      .where(territory: current_territory)
      .ordered_by_name
  end

  def pundit_user
    AgentContext.new(current_agent)
  end
end
