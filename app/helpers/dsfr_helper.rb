module DsfrHelper
  def dsfr_image_tag(path, alt, html_options = {})
    tag.figure(class: "fr-content-media") do
      tag.div(class: "fr-content-media__img") do
        image_tag(path, alt: alt, class: "fr-responsive-img #{html_options[:class]}")
      end
    end
  end

  def icon(icon_name, html_options = {})
    if html_options[:title]
      tag.span("", class: "#{icon_name} #{html_options.delete(:class)}", **html_options)
    else
      tag.span("", class: "#{icon_name} #{html_options.delete(:class)}", "aria-hidden": "true", **html_options)
    end
  end

  def motif_icon(html_options = {})
    icon("fr-icon-draft-fill", html_options)
  end

  def lieu_icon(html_options = {})
    icon("fr-icon-building-fill", html_options)
  end

  def user_icon(html_options = {})
    icon("fr-icon-user-fill", html_options)
  end

  def calendar_icon(html_options = {})
    icon("fr-icon-calendar-fill", html_options)
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

  def home_icon(html_options = {})
    icon("fr-icon-home-4-fill", html_options)
  end

  def settings_icon(html_options = {})
    icon("fr-icon-settings-5-fill", html_options)
  end

  def external_link_to(name, url, html_options = {})
    link_to(name, url, { target: "_blank", rel: "noopener", title: "#{name} - nouvel onglet" }.merge(html_options))
  end

  def location_type_icon(location_type, html_options = {})
    case location_type.to_sym
    when :public_office
      lieu_icon(html_options)
    when :phone
      phone_icon(html_options)
    when :home
      home_icon(html_options)
    when :visio
      visio_icon(html_options)
    end
  end

  def dsfr_return_btn_options
    # On met un margin-left négatif pour conserver l'alignement quand on n'est pas en train de hover sur le bouton
    { style: "margin-left: -16px", class: "fr-btn fr-btn--tertiary-no-outline fr-btn--icon-left fr-icon-arrow-left-line" }
  end
end
