# Source: https://github.com/etalab/data_pass/blob/develop/app/form_builders/dsfr_form_builder.rb
# Quelques modifications ont été appliquées car nous n’utilisons pas i18n pour les labels et les hints
# et nous n’utilisons pas tous les types de champs
class DsfrFormBuilder < ActionView::Helpers::FormBuilder
  include Rails.application.routes.url_helpers
  include ActionView::Helpers::OutputSafetyHelper

  attr_accessor :display_required_tags

  def initialize(object_name, object, template, options)
    super
    self.display_required_tags = options.fetch(:display_required_tags, true)
  end

  def dsfr_text_field(attribute, opts = {})
    dsfr_input_field(attribute, :text_field, opts)
  end

  def dsfr_email_field(attribute, opts = {})
    dsfr_input_field(attribute, :email_field, opts)
  end

  def dsfr_phone_field(attribute, opts = {})
    dsfr_input_field(attribute, :phone_field, opts)
  end

  def dsfr_input_group(attribute, opts, &block)
    @template.content_tag(:div, class: input_group_classes(attribute, opts), data: opts[:data]) do
      yield(block)
    end
  end

  def dsfr_input_field(attribute, input_kind, opts = {})
    dsfr_input_group(attribute, opts) do
      @template.safe_join(
        [
          dsfr_label_with_hint(attribute, opts),
          public_send(input_kind, attribute, class: "fr-input", **opts.except(:class)),
          dsfr_error_message(attribute),
        ]
      )
    end
  end

  def dsfr_label_with_hint(attribute, opts = {})
    label_class = "fr-label #{opts[:class]}"
    label(attribute, class: label_class) do
      label_and_tags = [label_value(attribute, opts)]
      label_and_tags.push(required_tag) if opts[:required] && display_required_tags
      label_and_tags.push(hint_tag(opts[:hint])) if opts[:hint]

      @template.safe_join(label_and_tags)
    end
  end

  def required_tag
    @template.content_tag(:span, "*", class: "fr-text-error")
  end

  def dsfr_error_message(attr)
    return if @object.errors[attr].none?

    @template.content_tag(:p, class: "fr-messages-group") do
      safe_join(@object.errors.full_messages_for(attr).map do |msg|
        @template.content_tag(:span, msg, class: "fr-message fr-message--error")
      end)
    end
  end

  def hint_tag(text)
    return "" unless text

    @template.content_tag(:span, class: "fr-hint-text") do
      text
    end

    @template.content_tag(:span, text, class: "fr-hint-text")
  end

  def join_classes(arr)
    arr.compact.join(" ")
  end

  def input_group_classes(attribute, opts)
    join_classes(
      [
        "fr-input-group",
        @object.errors[attribute].any? ? "fr-input-group--error" : nil,
        opts[:class],
      ]
    )
  end

  def label_value(attribute, opts)
    return opts[:label] if opts[:label]

    (@object.try(:object) || @object).class.human_attribute_name(attribute)
  end
end
