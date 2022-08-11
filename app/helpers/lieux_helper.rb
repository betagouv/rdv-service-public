# frozen_string_literal: true

module LieuxHelper
  def unavailability_tag(lieu)
    return if lieu.nil?
    return if lieu.availability.nil?
    return if lieu.enabled?

    tag.span(lieu.human_attribute_value(:availability),
             class: class_names("badge",
                                "badge-danger" => lieu.disabled?,
                                "badge-info" => lieu.single_use?,),)
  end
end
