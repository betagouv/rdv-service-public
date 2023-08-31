# frozen_string_literal: true

# La phrase du nom de la classe indique le contexte et l'action métier réalisés par ce service object en PORO
class AdminCreatesAgent
  def initialize(agent_params:, current_agent:, organisation:, access_level:)
    @agent_params = agent_params
    @current_agent = current_agent
    @organisation = organisation
    @access_level = access_level
  end

  def call
    Agent.transaction do
      @agent = find_agent

      if @agent
        add_agent_to_organisation
        check_agent_service
      elsif @access_level == "intervenant"
        @agent = Agent.create(agent_and_role_params)
      else
        @agent = Agent.invite!(agent_and_role_params, @current_agent)
      end

      if @agent.errors.none? # Si on relance des validations en appelant #valid?, on va déclencher les validations sur first_name et last_name
        AgentTerritorialAccessRight.find_or_create_by!(agent: @agent, territory: @organisation.territory)
      end
    end

    @agent
  end

  attr_reader :warning_message

  def confirmation_message
    return nil unless @agent.valid?

    if @agent.is_an_intervenant?
      "Intervenant créé avec succès."
    elsif @agent.invitation_accepted?
      I18n.t("activerecord.notice.models.agent_role.existing", email: @agent.email)
    else
      I18n.t("activerecord.notice.models.agent_role.invited", email: @agent.email)
    end
  end

  private

  def agent_and_role_params
    @agent_params.merge(
      roles_attributes: [
        organisation: @organisation,
        access_level: @access_level,
      ]
    )
  end

  def find_agent
    return nil if @agent_params[:email].blank?

    Agent.find_by(email: @agent_params[:email].downcase)
  end

  def add_agent_to_organisation
    @agent.update(
      roles_attributes: [
        organisation: @organisation,
        access_level: @access_level,
      ]
    )
  end

  def check_agent_service
    # Warn if the service isn’t the one that was requested
    service = Service.find(@agent_params[:service_id])

    if @agent.service != service
      @warning_message = I18n.t("activerecord.warnings.models.agent_role.different_service", service: service.name, agent_service: @agent.service.name)
    end
  end
end
