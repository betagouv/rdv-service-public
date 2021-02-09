module AdminHelper
  def collapsible_form_fields_for_warnings(model, &block)
    content_tag(
      :div,
      class: ["form-collapsable-fields-wrapper", "collapse", "js-collapse-warning-confirmation"] +
        (model.warnings_need_confirmation? ? [] : ["show"]),
      "aria-expanded": model.warnings_need_confirmation? ? "false" : "true",
      &block
    )
  end

  def display_value_or_na_placeholder(value)
    content_tag(
      :span,
      value.presence || "N/A",
      class: value.blank? ? "text-muted" : ""
    )
  end

  def current_agent_role
    return nil if current_agent.nil? || current_organisation.nil?

    @current_agent_role ||= current_agent.roles.find_by(organisation: current_organisation)
  end
end
