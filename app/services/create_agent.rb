# frozen_string_literal: true

class CreateAgent
  def initialize(agent_params, current_agent, organisation, access_level)
    @agent_params = agent_params
    @current_agent = current_agent
    @organisation = organisation
    @access_level = access_level
  end

  def call
    Agent.transaction do
      @agent = find_agent || Agent.create(@agent_params)

      add_agent_to_organisation
      check_agent_service
    end

    return @agent if @agent.invalid?

    if @agent.has_a_role_with_account_access? && @agent.organisations.count == 1
      @agent.invite!(@current_agent, validate: false)
    end

    @agent
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

  def add_agent_to_organisation
    @agent.roles.new(
      organisation: @organisation,
      access_level: @access_level
    )
    @agent.save(context: :invite) # Specify a different validation context to bypass last_name/first_name presence

    AgentTerritorialAccessRight.find_or_create_by!(agent: @agent, territory: @organisation.territory)
  end

  def check_agent_service
    # Warn if the service isn’t the one that was requested
    service = Service.find(@agent_params[:service_id])

    if @agent.service != service
      @warning_message = I18n.t("activerecord.warnings.models.agent_role.different_service", service: service.name, agent_service: agent.service.name)
    end
  end
end
