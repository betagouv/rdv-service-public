module DsfrHelper
  def dsfr_image_tag(path, alt, html_options = {})
    tag.figure(class: "fr-content-media") do
      tag.div(class: "fr-content-media__img") do
        image_tag(path, alt: alt, class: "fr-responsive-img #{html_options[:class]}")
      end
    end
  end

  def icon(icon_name, html_options = {})
    tag.span("", class: "#{icon_name} #{html_options.delete(:class)}", "aria-hidden": "true", **html_options)
  end

  def motif_icon(html_options = {})
    icon("fr-icon-draft-fill", html_options)
  end

  def lieu_icon(html_options = {})
    icon("fr-icon-building-fill", html_options)
  end

  def visio_icon(html_options = {})
    icon("fr-icon-mac-fill", html_options)
  end

  def phone_icon(html_options = {})
    icon("fr-icon-phone-fill", html_options)
  end

  def back_icon(html_options = {})
    icon("fr-icon-arrow-left-line", html_options)
  end

  def external_link_to(name, url, html_options = {})
    link_to(name, url, { target: "_blank", rel: "noopener", title: "#{name} - nouvel onglet" }.merge(html_options))
  end
end
