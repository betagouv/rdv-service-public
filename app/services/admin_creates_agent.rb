# La phrase du nom de la classe indique le contexte et l'action métier réalisés par ce service object en PORO
class AdminCreatesAgent
  def initialize(agent_params:, current_agent:, organisations:, access_level:)
    @agent_params = agent_params
    @current_agent = current_agent
    @organisations = organisations
    @access_level = access_level
  end

  def call
    Agent.transaction do
      @agent = find_agent

      if @agent
        add_agent_to_organisations
        @warning_message = self.class.check_agent_service(@agent, @agent_params[:service_ids])
      elsif @access_level == "intervenant"
        @agent = Agent.create(
          agent_and_role_params.merge(
            rdv_notifications_level: "none",
            plage_ouverture_notification_level: "none",
            absence_notification_level: "none"
          )
        )
      else
        @agent = Agent.invite!(agent_and_role_params.merge(allow_blank_name: true), @current_agent)
      end

      if @agent.valid? && @organisations.any?
        AgentTerritorialAccessRight.find_or_create_by!(agent: @agent, territory: @organisations.first.territory)
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

  # @return [String, nil] the error message if requested services don't match curent services of the agent
  def self.check_agent_service(agent, service_ids)
    services = Service.where(id: service_ids)

    if agent.services.to_set != services.to_set
      I18n.t("activerecord.warnings.models.agent_role.different_services", services: services.map(&:short_name).join(", "), agent_services: agent.services_short_names)
    end
  end

  private

  def agent_and_role_params
    @agent_params.merge(
      roles_attributes: @organisations.to_a.map do |organisation|
        {
          organisation: organisation,
          access_level: @access_level,
        }
      end
    )
  end

  def find_agent
    return nil if @agent_params[:email].blank?

    Agent.find_by(email: @agent_params[:email].downcase)
  end

  def add_agent_to_organisations
    @organisations.each do |organisation|
      @agent.update(
        allow_blank_name: true,
        roles_attributes: [
          organisation: organisation,
          access_level: @access_level,
        ]
      )
    end
  end
end
