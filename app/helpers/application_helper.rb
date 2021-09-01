# frozen_string_literal: true

module ApplicationHelper
  # Usage: class_names('my-class', 'my-other-class': condition)
  def class_names(*args) # replace with the rails 6 thing
    optional = args.last.is_a?(Hash) ? args.last : {}
    mandatory = optional.empty? ? args : args[0..-2]

    optional = optional.map do |class_name, condition|
      class_name if condition
    end
    (Array(mandatory) + optional).flatten.compact.map(&:to_s).uniq
  end

  def alert_class_for(alert)
    case alert
    when :success
      "alert-success"
    when :alert
      "alert-warning"
    when :error
      "alert-danger"
    when :notice
      "alert-info"
    else
      alert.to_s
    end
  end

  def datetime_input(form, field)
    form.input(field, as: :string, input_html: { value: form.object.send(field)&.strftime("%d/%m/%Y %H:%M"), data: { behaviour: "datetimepicker" }, autocomplete: "off" })
  end

  def date_input(form, field, label = nil, input_html: {}, **kwargs)
    form.input(
      field,
      as: :string,
      label: label,
      input_html: {
        value: form.object&.send(field)&.strftime("%d/%m/%Y"),
        data: { behaviour: "datepicker" },
        autocomplete: "off",
        placeholder: "__/__/___"
      }.deep_merge(input_html),
      **kwargs
    )
  end

  def time_input(form, field)
    form.input(field, as: :string, input_html: { value: form.object.send(field)&.strftime("%H:%M"), data: { behaviour: "timepicker" }, autocomplete: "off" })
  end

  def agents_or_users_body_class
    agent_path? ? "agents" : "users"
  end

  def link_logo
    link_to root_path do
      image_pack_tag "logos/logo.svg", height: 40, alt: "RDV Solidarités", class: "d-inline logo"
    end
  end

  def map_tag_marker(title) # Unused ?
    icon_tag_tooltip(title, "map-marker-alt")
  end

  def icon_tag_tooltip(title, icon) # Unused ?
    tag.i(nil, class: "fa fa-#{icon}", data: { toggle: "tooltip" }, title: title)
  end

  def errors_full_messages(object)
    object.errors.map do |attribute, message|
      if attribute.to_s.starts_with?("responsible.")
        att = attribute.to_s.sub(/^responsible./, "")
        "Responsable: #{object.errors.full_message(att, message)}"
      else
        object.errors.full_message(attribute, message)
      end
    end
  end

  def apple_mobile_device?
    user_agent = request.headers["User-Agent"]&.downcase || ""
    user_agent.include?("apple") && user_agent.include?("mobile")
    # HACK: avoids including a full-blown gem like `browser`
  end

  def human_id(organisation_or_sector)
    tag.span(organisation_or_sector.human_id, class: "badge badge-light text-monospace")
  end
end
