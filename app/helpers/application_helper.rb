module ApplicationHelper

  # Usage: class_names('my-class', 'my-other-class': condition)
  def class_names(*args)
    optional = args.last.is_a?(Hash) ? args.last : {}
    mandatory = optional.length > 0 ? args[0..-2] : args

    optional = optional.map do |class_name, condition|
      class_name if condition
    end
    (Array(mandatory) + optional).flatten.compact.map(&:to_s).uniq
  end

  def alert_class_for alert
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
  
end
