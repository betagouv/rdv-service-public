module AdminHelper
  def collapsible_form_fields_for_warnings(model, &block)
    tag.div(class: %w[form-collapsable-fields-wrapper collapse js-collapse-warning-confirmation] +
        (model.errors_are_all_benign? ? [] : ["show"]),
            "aria-expanded": model.errors_are_all_benign? ? "false" : "true", &block)
  end

  def display_value_or_na_placeholder(value)
    tag.span(value.presence || "N/A", class: value.blank? ? "text-muted" : "")
  end

  def current_agent_role
    return nil if current_agent.nil? || current_organisation.nil?

    @current_agent_role ||= current_agent.roles.find_by(organisation: current_organisation)
  end

  # Build a dummy model linked the organisation to fetch its policy.
  # eg. current_agent_can_create_agent_in?(current_organisation)
  def current_agent_can_create_agent_in?(organisation)
    mock_agent = Agent.new(organisations: [organisation])
    policy(mock_agent, policy_class: Agent::AgentPolicy).create?
  end
end
