# frozen_string_literal: true

# Ce form builder a été copié depuis :
# https://github.com/betagouv/collectif-objets
#
# Voir doc sur FormBuilder:
# https://api.rubyonrails.org/v7.0.4/classes/ActionView/Helpers/FormBuilder.html

class FormBuilderDsfr < ActionView::Helpers::FormBuilder
  def label(method, name = nil, options = {})
    add_class(options, "fr-label")
    super
  end

  def text_field(method, options = {})
    add_class(options, "fr-input")
    super(method, options)
  end

  def search_field(method, options = {})
    add_class(options, "fr-input")
    super(method, options)
  end

  def email_field(method, options = {})
    add_class(options, "fr-input")
    super(method, options)
  end

  def password_field(method, options = {})
    add_class(options, "fr-input")
    super(method, options)
  end

  def text_area(method, options = {})
    add_class(options, "fr-input")
    super(method, options)
  end

  def select(method, choices, options = {}, html_options = {})
    html_options = html_options.with_indifferent_access
    add_class(html_options, "fr-select")
    super(method, choices, options, html_options)
  end

  def submit(value, options = {})
    options = options.with_indifferent_access
    add_class(options, "fr-btn")
    super(value, options)
  end

  private

  def add_class(options, classes)
    options[:class] ||= ""
    options[:class] += " #{classes}"
  end
end
