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
      'alert-success'
    when :alert
      'alert-warning'
    when :error
      'alert-danger'
    when :notice
      'alert-info'
    else
      alert.to_s
    end
  end

  def root_path?
    request.path == root_path
  end

  def datetime_input(form, field)
    form.input(field, as: :string, input_html: { value: form.object.send(field)&.strftime("%d/%m/%Y %H:%M"), data: { behaviour: 'datetimepicker' }, autocomplete: "off" })
  end

  def date_input(form, field, label = nil, input_html: {})
    form.input(field, as: :string, label: label, input_html: { value: form.object.send(field)&.strftime("%d/%m/%Y"), data: { behaviour: 'datepicker' }, autocomplete: "off" }.deep_merge(input_html))
  end

  def time_input(form, field)
    form.input(field, as: :string, input_html: { value: form.object.send(field)&.strftime("%H:%M"), data: { behaviour: 'timepicker' }, autocomplete: "off" })
  end

  def add_button(label, path, header: false)
    link_to label, path, class: "btn #{header ? "btn-outline-white" : "btn-primary"}", data: { rightbar: true }
  end

  def holder_tag(size, text = '', theme = nil, html_options = {}, holder_options = {})
    size = "#{size}x#{size}" unless size =~ /\A\d+p?x\d+\z/

    holder_options[:text] = text unless text.to_s.empty?
    holder_options[:theme] = theme unless theme.nil?
    holder_options = holder_options.map { |e| e.join('=') }.join('&')

    options = { src: '', data: { src: "holder.js/#{size}?#{holder_options}" } }
    options = options.merge(html_options)

    tag :img, options
  end

  def agent_path?
    request.path =~ /(agents)/
  end

  def agents_or_users_body_class
    agent_path? ? 'agents' : 'users'
  end
end
