# frozen_string_literal: true

module ApplicationHelper
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

  def errors_full_messages(object)
    object.not_benign_errors.map do |error|
      if error.attribute.to_s.starts_with?("responsible.")
        att = error.attribute.to_s.sub(/^responsible./, "")
        "Responsable: #{object.errors.full_message(att, error.message)}"
      else
        object.errors.full_message(error.attribute, error.message)
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

  def aligned_flex_row(fa_icon_name, &block)
    tag.div(class: "flex-row-aligned") do
      tag.i(class: class_names("fa", fa_icon_name)) + tag.div(&block)
    end
  end

  def boolean_tag(value, &block)
    fa_icon_name = value ? "fa-check" : "fa-exclamation-triangle text-warning"
    aligned_flex_row(fa_icon_name, &block)
  end

  def boolean_attribute_tag(object, attribute_name)
    value = object.send(attribute_name)
    boolean_tag(value) { object.class.human_attribute_name("#{attribute_name}.#{value}") }
  end

  def admin_link_to_if_permitted(organisation, object, name = object.to_s)
    if policy([:agent, object]).show?
      link_to name, polymorphic_path([:admin, organisation, object])
    else
      name
    end
  end
end
