# frozen_string_literal: true

module MotifsHelper
  YIQ_DARK_LIGHT_FRONTIER = 128

  def motif_name_with_location_type(motif)
    "#{motif.name} (#{Motif.human_enum_name(:location_type, motif.location_type)})"
  end

  def motif_name_with_special_location_type(motif)
    motif.public_office? ? motif.name : motif_name_with_location_type(motif)
  end

  def motif_name_with_location_type_and_badges(motif)
    tag.span(motif_name_with_location_type(motif)) + motif_badges(motif)
  end

  def motif_badges(motif, only: %i[reservable_online secretariat follow_up])
    safe_join(only.select { motif.send("#{_1}?") }.map { build_badge_tag_for(_1) })
  end

  def build_badge_tag_for(badge_name)
    tag.span(I18n.t("motifs.badges.#{badge_name}"), class: "badge badge-motif-#{badge_name}")
  end

  def min_max_delay_options
    [["1/2 heure", 30.minutes], ["1 heure", 1.hour], ["2 heures", 2.hours],
     ["3 heures", 3.hours], ["6 heures", 6.hours], ["12 heures", 12.hours],
     ["1 jour", 1.day], ["2 jours", 2.days], ["3 jours", 3.days], ["1 semaine", 1.week], ["2 semaines", 2.weeks],
     ["1 mois", 1.month], ["2 mois", 2.months], ["3 mois", 3.months], ["6 mois", 6.months], ["1 an", 1.year]]
  end

  def min_max_delay_int_to_human(int_value)
    min_max_delay_options.map { |arr| [arr[0], arr[1].to_i] }.to_h.invert[int_value]
  end

  def text_color(color)
    return "white" if color.blank?

    dark_or_light?(color) ? "#000000" : "#FFFFFF"
  end

  def dark_or_light?(color)
    convert_hexa_color_to_yiq(color) >= YIQ_DARK_LIGHT_FRONTIER
  end

  def convert_hexa_color_to_yiq(color)
    red, green, blue = *convert_hexa_color_to_rgb(color)
    ((red * 299) + (green * 587) + (blue * 114)) / 1000
  end

  def convert_hexa_color_to_rgb(color)
    [Integer("0x#{color[1..2]}"), Integer("0x#{color[3..4]}"), Integer("0x#{color[5..6]}")]
  end

  def motif_option_value(motif, option_name)
    if motif.send("#{option_name}?")
      tag.span("☑️ ") + tag.span(t("activerecord.attributes.motif.#{option_name}_hint"))
    else
      tag.span("╳ désactivée", class: "text-muted")
    end
  end

  def motif_attribute_row(legend, arg_value = nil, hint: nil, &block)
    value = block.present? ? capture(&block) : display_value_or_na_placeholder(arg_value)
    value += tag.div(hint, class: "text-muted") if arg_value.present? && hint.present?
    tag.div(tag.div(legend, class: "col-md-4 text-bold text-right") +
        tag.div(value, class: "col-md-8"), class: "row")
  end

  def cancel_warning_message
    cancel_warning_message || t("activerecord.attributes.motif.default_cancel_warning_message")
  end
end
