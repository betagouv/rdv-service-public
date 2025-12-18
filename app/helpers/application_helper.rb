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

  def alert_dsfr_type_for(alert)
    case alert
    when :success
      :success
    when :alert
      :warning
    when :error
      :error
    when :notice
      :info
    else
      raise ArgumentError, "alert should be a key among :success, :alert, :error or :notice"
    end
  end

  def datetime_input(form, field, input_html: {}, options: {})
    form.input(
      field,
      {
        as: :string,
        input_html: {
          value: form.object.send(field)&.strftime("%d/%m/%Y %H:%M"),
          data: { behaviour: "datetimepicker" },
          autocomplete: "off",
        }.deep_merge(input_html),
      }.deep_merge(options)
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

  def link_logo
    link_to root_path do
      image_tag current_domain.dark_logo_path, height: 40, alt: current_domain.name, class: "d-inline logo"
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

  def boolean_tag(value, &block)
    icon_classes = value ? "fr-icon-checkbox-fill" : "fr-icon-warning-fill text-warning"

    tag.div(class: "flex-row-aligned") do
      tag.span(class: icon_classes) + tag.div(&block)
    end
  end

  def boolean_attribute_tag(object, attribute_name)
    value = object.send(attribute_name)
    boolean_tag(value) { object.class.human_attribute_value(attribute_name, value) }
  end

  def object_attribute_tag(object, attribute_name, value = :delegate_to_object)
    name = object.class.human_attribute_name(attribute_name)

    if value == :delegate_to_object
      value = object.human_attribute_value(attribute_name)
    end

    tag.strong(tag.span(name) + tag.span(" : ")) +
      tag.span(value.presence || "Non renseigné", class: class_names("text-muted": value.blank?))
  end

  def self_anchor(identifier, &block)
    tag.a(id: identifier, href: "##{identifier}", &block)
  end

  def display_pro_connect_button?
    return false unless current_domain.pro_connect_client_id

    return true if params[:force_pro_connect].present? # Permet de tester manuellement ProConnect avant de désactiver la variable d'env PRO_CONNECT_DISABLED

    return false if ENV["PRO_CONNECT_DISABLED"]
    return false if Rails.configuration.x.pro_connect_unreachable_at_boot_time

    ENV["PRO_CONNECT_BASE_URL"].present?
  end

  def display_france_connect_v2_button?
    return false unless current_domain.france_connect_enabled

    return true if params[:force_france_connect_v2].present? # Permet de tester manuellement France Connect avant de désactiver la variable d'env FRANCE_CONNECT_V2_DISABLED

    return false if ENV["FRANCE_CONNECT_V2_DISABLED"]
    return false if Rails.configuration.x.france_connect_v2_unreachable_at_boot_time

    ENV["FRANCECONNECT_V2_BASE_URL"].present?
  end

  def dsfr_path
    "/dsfr-v1.13.2"
  end

  def dsfr_svg(path, custom: false, **kwargs)
    # cf https://www.systeme-de-design.gouv.fr/fondamentaux/pictogramme
    classes = ["fr-artwork"]
    classes += [kwargs.fetch(:class, nil)]
    path = "#{dsfr_path}/#{path}.svg" unless custom
    tag.svg(class: classes.compact_blank.join(" "), "aria-hidden": "true", viewBox: "0 0 80 80", width: "80px", height: "80px") do
      tag.use(class: "fr-artwork-decorative", "xlink:href": "#{path}#artwork-decorative") +
        tag.use(class: "fr-artwork-minor", "xlink:href": "#{path}#artwork-minor") +
        tag.use(class: "fr-artwork-major", "xlink:href": "#{path}#artwork-major")
    end
  end

  # Ce helper est un remplacement de chartkick qui est compatible avec notre security content policy qui interdit les unsafe inline
  def column_chart(path, options = {})
    tag.div(class: "js-column-chart", data: { path: path, options: options.to_json })
  end
end
