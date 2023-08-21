# frozen_string_literal: true

class CreateAgent
  def initialize(agent_params, current_agent, organisation)
    @agent_params = agent_params
    @current_agent = current_agent
    @organisation = organisation
  end

  def call
    @agent = find_agent || create_agent

    add_agent_to_organisation

    if !intervenant? && @agent.organisations.count == 1
      @agent.invite!(@current_agent, validate: false)
    end

    true
  end

  attr_reader :warning_message

  def confirmation_message
    return nil unless @agent.valid?

    if @agent.is_an_intervenant?
      "Intervenant créé avec succès."
    elsif @agent.invitation_accepted?
      I18n.t("activerecord.notice.models.agent_role.existing", email: agent.email)
    else
      I18n.t("activerecord.notice.models.agent_role.invited", email: agent.email)
    end
  end

  private

  def find_agent
    return nil if @agent_params[:email].blank?

    Agent.find_by(email: @agent_params[:email].downcase)
  end

  def create_agent
    Agent.create(@agent_params).tap do |agent|
      AgentTerritorialAccessRight.find_or_create_by!(agent: agent, territory: @organisation.territory)
    end
  end

  def add_agent_to_organisation
    @agent.roles.new(
      organisation: current_organisation,
      access_level: access_level
    )
    @agent.save(context: :invite) # Specify a different validation context to bypass last_name/first_name presence

    # Warn if the service isn’t the one that was requested
    service = services.find(@agent_params[:service_id])

    if agent.service != service
      @warning_message = I18n.t("activerecord.warnings.models.agent_role.different_service", service: service.name, agent_service: agent.service.name)
    end
  end

  def access_level
    if @current_agent.conseiller_numerique?
      AgentRole::ACCESS_LEVEL_BASIC
    else
      @agent_params[:roles_attributes]["0"]["access_level"]
    end
  end
end
