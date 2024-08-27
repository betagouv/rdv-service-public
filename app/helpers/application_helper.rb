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

  def datetime_input(form, field, input_html: {})
    form.input(
      field,
      as: :string,
      input_html: {
        value: form.object.send(field)&.strftime("%d/%m/%Y %H:%M"),
        data: { behaviour: "datetimepicker" },
        autocomplete: "off",
      }.deep_merge(input_html)
    )
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
        placeholder: "__/__/___",
      }.deep_merge(input_html),
      **kwargs
    )
  end

  def fake_required_label(label)
    sanitize("#{label} <abbr title=\"obligatoire\">*</abbr>")
  end

  def link_logo
    link_to root_path do
      image_tag current_domain.logo_path, height: 40, alt: current_domain.name, class: "d-inline logo"
    end
  end

  def link_logo_dsfr
    link_to root_path, class: "header-brand" do
      concat image_tag("logos/republique-francaise-logo.svg", alt: "République Française", class: "logo-brand mb-2 mr-3")
      concat image_tag current_domain.dark_logo_path, alt: current_domain.name, class: "logo-dsfr"
    end
  end

  def errors_full_messages(object)
    errors = object.respond_to?(:not_benign_errors) ? object.not_benign_errors : object.errors
    errors.map do |error|
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

  def human_id(sector)
    tag.span(sector.human_id, class: "badge badge-light text-monospace")
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
    boolean_tag(value) { object.class.human_attribute_value(attribute_name, value) }
  end

  def object_attribute_tag(object, attribute_name, value = nil)
    name = object.class.human_attribute_name(attribute_name)
    value ||= object.human_attribute_value(attribute_name)

    tag.strong(tag.span(name) + tag.span(" : ")) +
      tag.span(value.presence || "Non renseigné", class: class_names("text-muted": value.blank?))
  end

  def admin_link_to_if_permitted(organisation, object, name = object.to_s)
    if policy([:agent, object]).show?
      link_to name, polymorphic_path([:admin, organisation, object])
    else
      name
    end
  end

  def self_anchor(identifier, &block)
    tag.a(id: identifier, href: "##{identifier}", data: { turbolinks: false }, &block)
  end

  def display_agent_connect_button?
    (ENV["AGENT_CONNECT_BASE_URL"].present? && !ENV["AGENT_CONNECT_DISABLED"]) || params[:force_agent_connect].present?
  end

  def display_inclusion_connect_button?
    !ENV["INCLUSIONCONNECT_DISABLED"] || params[:force_inclusionconnect].present?
  end
end
