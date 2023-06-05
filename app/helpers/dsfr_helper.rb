# frozen_string_literal: true

module DsfrHelper
  def dsfr_image_tag(path, alt, html_options = {})
    tag.figure(class: "fr-content-media") do
      tag.div(class: "fr-content-media__img") do
        image_tag(path, alt: alt, class: "fr-responsive-img #{html_options[:class]}")
      end
    end
  end

  def external_link_to(name, url, html_options = {})
    link_to(name, url, { target: "_blank", rel: "noopener", title: "#{name} - nouvel onglet" }.merge(html_options))
  end
end
