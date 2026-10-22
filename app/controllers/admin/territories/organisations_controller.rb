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
    member_organisations = policy_scope(current_territory.organisations, policy_scope_class: Agent::OrganisationPolicy::Scope)
    joinable_organisations = policy_scope(current_territory.organisations, policy_scope_class: Agent::OrganisationPolicy::JoinableScope)
    @organisations = current_territory.organisations
      .where_id_in_subqueries([member_organisations, joinable_organisations])
      .where(disabled_at: nil)
      .ordered_by_name
    @closed_organisations = current_territory.organisations.where.not(disabled_at: nil)
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
      organisation.update!(disabled_at: Time.zone.now)
      flash[:success] = "L'organisation a été fermée."
    else
      flash[:error] = "L'organisation n'a pas pu être fermée parce que des agents on encore des rendez-vous à venir dans cette organisation."
    end

    redirect_to admin_territory_organisations_path(organisation.territory)
  end

  def confirm_reopen
    @organisation = Organisation.find(params[:id])
    authorize(@organisation, :reopen?, policy_class: Agent::OrganisationPolicy)
  end

  def reopen
    @organisation = Organisation.find(params[:id])
    authorize(@organisation, :reopen?, policy_class: Agent::OrganisationPolicy)
    @organisation.transaction do
      AgentRole.create!(organisation: @organisation, agent: current_agent, access_level: :admin)
      @organisation.update!(disabled_at: nil)
    end
    redirect_to admin_organisation_configuration_path(@organisation),
                flash: { success: "Organisation rouverte ! Vous pouvez inviter des agents à la rejoindre." }
  end

  def join
    organisation = current_territory.organisations.find(params[:id])
    authorize(organisation, :join?, policy_class: Agent::OrganisationPolicy)
    # create_or_find_by! évite une erreur d'unicité en cas de double clic sur le bouton
    AgentRole.create_or_find_by!(organisation: organisation, agent: current_agent) do |agent_role|
      agent_role.access_level = AgentRole::ACCESS_LEVEL_ADMIN
    end
    AgentSensitiveAccountCalculator.refresh_agent!(current_agent)
    redirect_to admin_organisation_configuration_path(organisation),
                flash: { success: "Vous êtes maintenant administrateur de l'organisation #{organisation.name}." }
  end
end
