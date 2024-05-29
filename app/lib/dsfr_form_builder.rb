# copied from https://github.com/etalab/data_pass/blob/develop/app/form_builders/dsfr_form_builder.rb

class DsfrFormBuilder < ActionView::Helpers::FormBuilder
  include Rails.application.routes.url_helpers

  def dsfr_text_field(attribute, opts = {})
    dsfr_input_field(attribute, :text_field, opts)
  end

  def dsfr_email_field(attribute, opts = {})
    dsfr_input_field(attribute, :email_field, opts)
  end

  def dsfr_date_field(attribute, opts = {})
    dsfr_input_field(attribute, :date_field, opts)
  end

  def dsfr_text_area(attribute, opts = {})
    dsfr_input_field(attribute, :text_area, opts)
  end

  def dsfr_number_field(attribute, opts = {})
    dsfr_input_field(attribute, :number_field, opts)
  end

  def dsfr_url_field(attribute, opts = {})
    dsfr_input_field(attribute, :url_field, opts)
  end

  def dsfr_file_field(attribute, opts = {})
    opts[:class] ||= "fr-upload-group"

    dsfr_input_group(attribute, opts) do
      @template.safe_join(
        [
          label_with_hint(attribute),
          file_field(attribute, class: "fr-upload", autocomplete: "off", **enhance_input_options(opts).except(:class)),
          error_message(attribute),
          link_to_file(attribute),
        ]
      )
    end
  end

  def dsfr_check_box(attribute, opts = {})
    dsfr_input_group(attribute, opts) do
      @template.content_tag(:div, class: "fr-checkbox-group") do
        @template.safe_join(
          [
            check_box(attribute, class: input_classes(opts), disabled: check_box_disabled, **enhance_input_options(opts).except(:class)),
            opts[:label_with_hint] || label_with_hint(attribute),
          ]
        )
      end
    end
  end

  def dsfr_input_group(attribute, opts, &block)
    @template.content_tag(:div, class: input_group_classes(attribute, opts)) do
      yield(block)
    end
  end

  def dsfr_radio_buttons(attribute, choices, opts = {})
    @template.content_tag(:fieldset, class: "fr-fieldset") do
      @template.safe_join(
        [
          @template.content_tag(
            :legend,
            @object.class.human_attribute_name(attribute).concat(hint(attribute)).html_safe,
            class: "fr-fieldset__legend--regular fr-fieldset__legend"
          ),
          choices.map { |choice| dsfr_radio_option(attribute, choice, opts) },
        ]
      )
    end
  end

  def dsfr_radio_option(attribute, value, opts = {})
    @template.content_tag(:div, class: "fr-fieldset__element") do
      @template.content_tag(:div, class: "fr-radio-group") do
        @template.safe_join(
          [
            radio_button(attribute, value, **opts),
            label([attribute, value].join("_").to_sym, value: label_value(attribute)),
          ]
        )
      end
    end
  end

  def dsfr_select(attribute, choices, opts = {})
    @template.content_tag(:div, class: "fr-select-group") do
      @template.safe_join(
        [
          label_with_hint(attribute),
          dsfr_select_tag(attribute, choices, opts),
          error_message(attribute),
        ]
      )
    end
  end

  private

  def dsfr_select_tag(attribute, choices, opts)
    select(attribute, choices, {}, class: "fr-select", **enhance_input_options(opts).except(:class))
  end

  def dsfr_input_field(attribute, input_kind, opts = {})
    dsfr_input_group(attribute, opts) do
      @template.safe_join(
        [
          label_with_hint(attribute),
          public_send(input_kind, attribute, class: input_classes(opts), autocomplete: "off", **enhance_input_options(opts).except(:class)),
          error_message(attribute),
        ]
      )
    end
  end

  def label_with_hint(attribute)
    label(attribute, class: "fr-label") do
      @template.safe_join(
        [
          label_value(attribute),
          hint(attribute),
        ]
      )
    end
  end

  def hint(attribute)
    text = hint_for(attribute)

    return "" if text.blank?

    @template.content_tag(:span, class: "fr-hint-text") do
      text
    end

    @template.content_tag(:span, text.html_safe, class: "fr-hint-text")
  end

  def error_message(attr)
    return if @object.errors[attr].none?

    @template.content_tag(:p, class: "fr-messages-group") do
      @object.errors.full_messages_for(attr).map do |msg|
        @template.content_tag(:span, msg, class: "fr-message fr-message--error")
      end.join.html_safe
    end
  end

  def join_classes(arr)
    arr.compact.join(" ")
  end

  def input_classes(opts)
    join_classes(
      [
        "fr-input",
        opts[:code] && "fr-input--code",
        input_width_class(opts),
      ]
    )
  end

  def link_to_file(attribute)
    return unless @object.send(attribute).attached? && @object.send(attribute).persisted?

    @template.content_tag(:div, class: "fr-input-group__text") do
      @template.link_to("Voir le document", rails_blob_path(@object.send(attribute), disposition: "inline", only_path: true), target: "_blank", rel: "noopener")
    end
  end

  def input_width_class(opts)
    return "" if opts[:width].blank?

    opts[:width].split.map { |spec| "fr-col-#{spec}" }.join(" ")
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

  def hint_for(attribute)
    I18n.t("activerecord.hints.#{@object.model_name.element}.#{attribute}", default: nil)
  end

  def label_value(attribute)
    (@object.try(:object) || @object).class.human_attribute_name(attribute)
  end

  def enhance_input_options(opts)
    opts
  end

  def check_box_disabled
    false
  end
end
