# frozen_string_literal: true

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

  # Build a dummy model linked the current_organisation to fetch its policy.
  # eg. current_agent_can?(:create, Lieu)
  def current_agent_can?(action, klass)
    if klass.reflections.include?("organisations")
      # klass has_many :organisations
      mock = klass.new(organisations: [current_organisation])
    elsif klass.reflections.include?("organisation")
      # klass has_one or belongs_to :organisation
      mock = klass.new(organisation: current_organisation)
    else
      raise "Invalid klass for current_agent_can?: #{klass}  has no organisation association."
    end
    policy([:agent, mock]).send("#{action}?")
  end
end
