module ApplicationHelper
  # Usage: class_names('my-class', 'my-other-class': condition)
  def class_names(*args)
    optional = args.last.is_a?(Hash) ? args.last : {}
    mandatory = !optional.empty? ? args[0..-2] : args

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

  def add_button(label, path, header: false)
    link_to label, path, class: "btn #{header ? "btn-outline-white" : "btn-primary"}", data: { rightbar: true }
  end

  def holder_tag(size, text = "", theme = nil, html_options = {}, holder_options = {})
    size = "#{size}x#{size}" unless size =~ /\A\d+p?x\d+\z/

    holder_options[:text] = text unless text.to_s.empty?
    holder_options[:theme] = theme unless theme.nil?
    holder_options = holder_options.map { |e| e.join("=") }.join("&")

    options = { src: "", data: { src: "holder.js/#{size}?#{holder_options}" } }
    options = options.merge(html_options)

    tag :img, options
  end

  def agents_or_users_body_class
    agent_path? ? "agents" : "users"
  end

  def link_logo
    link_to root_path do
      image_pack_tag "logos/logo.svg", height: 40, alt: "RDV Solidarités", class: "d-inline logo"
    end
  end

  def map_tag_marker(title)
    icon_tag_tooltip(title, "map-marker-alt")
  end

  def question_tag_tooltip(title)
    icon_tag_tooltip(title, "question-circle")
  end

  def icon_tag_tooltip(title, icon)
    content_tag(:i, nil, class: "fa fa-#{icon}", data: { toggle: "tooltip" }, title: title)
  end

  def display_value_or_na_placeholder(field_value)
    field_value.blank? ? "Non renseigné" : field_value
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
end
