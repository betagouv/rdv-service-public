# frozen_string_literal: true

module DsfrHelper
  def dsfr_image_tag(path, alt:, classes: "")
    tag.figure(class: "fr-content-media") do
      tag.div(class: "fr-content-media__img") do
        image_tag(path, alt: alt, class: "fr-responsive-img #{classes}")
      end
    end
  end
end
