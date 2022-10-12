# frozen_string_literal: true

module LieuxHelper
  def unavailability_tag(lieu)
    return if lieu.nil?
    return if lieu.availability.nil?
    return if lieu.enabled?

    tag.span(lieu.human_attribute_value(:availability),
             class: class_names("badge",
                                "badge-danger" => lieu.disabled?,
                                "badge-info" => lieu.single_use?))
  end

  def lieu_tag(lieu)
    return if lieu.nil?

    content_tag(:span) do
      concat lieu.name
      concat unavailability_tag(lieu)
      concat tag.br
      concat content_tag(:small, lieu.address)
    end
  end
end
