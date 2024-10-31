module MotifsHelper
  YIQ_DARK_LIGHT_FRONTIER = 128

  def motif_name_and_location_type(motif)
    "#{motif.name} (#{motif.human_attribute_value(:location_type)})"
  end

  def motif_name_with_location_and_group_type(motif)
    "#{motif.name} (#{motif.human_attribute_value(:location_type)} - #{human_group_type_value(motif)})"
  end

  def motif_name_and_service(motif)
    "#{motif.name} - #{motif.service.name}"
  end

  def motif_name_with_special_location_type(motif)
    motif.public_office? ? motif.name : motif_name_and_location_type(motif)
  end

  def motif_name_with_location_type_and_badges(motif)
    tag.span(motif_name_and_location_type(motif)) + motif_badges(motif)
  end

  def motif_badges(motif, only: %i[bookable_by_invited_users bookable_by_everyone bookable_by_agents_and_prescripteurs for_secretariat follow_up collectif])
    safe_join(only.select { motif.send("#{_1}?") }.map { build_badge_tag_for(_1) })
  end

  def motif_name_with_location_type_and_status(motif)
    return motif_name_and_location_type(motif) if motif.deleted_at.blank?

    "#{motif_name_and_location_type(motif)} (supprimé)"
  end

  def build_badge_tag_for(badge_name)
    tag.span(I18n.t("motifs.badges.#{badge_name}"), class: "badge badge-motif-#{badge_name}")
  end

  # L'option "agents_and_prescripteurs_and_invited_users"
  # n'est offerte que dans des organisations RDV-I.
  def bookable_by_types(rdvi_mode:)
    if rdvi_mode
      Motif.bookable_bies.keys
    else
      Motif.bookable_bies.keys - ["agents_and_prescripteurs_and_invited_users"]
    end
  end

  def bookable_by_filter_options(rdvi_mode:)
    [["-", ""]] + bookable_by_types(rdvi_mode: rdvi_mode).map { [t("admin.motifs.bookable_by_types.#{_1}"), _1] }
  end

  def min_max_delay_options
    [["1/2 heure", 30.minutes], ["1 heure", 1.hour], ["2 heures", 2.hours],
     ["3 heures", 3.hours], ["6 heures", 6.hours], ["12 heures", 12.hours],
     ["1 jour", 1.day], ["2 jours", 2.days], ["3 jours", 3.days], ["1 semaine", 1.week], ["2 semaines", 2.weeks], ["3 semaines", 3.weeks],
     ["1 mois", 1.month], ["2 mois", 2.months], ["3 mois", 3.months], ["6 mois", 6.months], ["1 an", 1.year],]
  end

  def min_max_delay_int_to_human(int_value)
    min_max_delay_options.to_h { |arr| [arr[0], arr[1].to_i] }.invert[int_value]
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
    color = convert_to_hexa(color)
    [Integer("0x#{color[1..2]}"), Integer("0x#{color[3..4]}"), Integer("0x#{color[5..6]}")]
  end

  def convert_to_hexa(color)
    return color if color[0] == "#"

    CSS_COLOR_NAMES[color] || "#FFFFFF"
  end

  def motif_option_value(motif, option_name)
    if motif.send("#{option_name}?")
      tag.span("☑️ ") + tag.span(Motif.human_attribute_name("#{option_name}_hint"))
    else
      tag.span("désactivée", class: "text-muted")
    end
  end

  def motif_option_activated(motif, option_name)
    if motif.send("#{option_name}?")
      tag.span("Oui")
    else
      tag.span("désactivée", class: "text-muted")
    end
  end

  def motif_attribute_row(legend, arg_value = nil, hint: nil, &block)
    value = block.present? ? capture(&block) : display_value_or_na_placeholder(arg_value)
    value += tag.div(hint, class: "text-muted") if arg_value.present? && arg_value.exclude?("text-muted") && hint.present?
    tag.div(tag.div(legend, class: "col-md-4 text-right") +
        tag.div(value, class: "col-md-8 text-bold"), class: "row")
  end

  def human_group_type_value(motif)
    t("activerecord.attributes.motif/collectifs.#{motif.collectif?}")
  end

  def available_slots_count(motif)
    if motif.collectif?
      motif.rdvs.collectif_and_available_for_reservation.count
    else
      policy_scope(PlageOuverture, policy_scope_class: Agent::PlageOuverturePolicy::Scope).joins(:motifs).where(
        organisation: current_organisation,
        motifs: { id: motif.id }
      ).in_range(Time.zone.now..).count
    end
  end

  def restriction_for_rdv_to_html(motif)
    auto_link(simple_format(motif.restriction_for_rdv, {}, wrapper_tag: "span"), html: { target: "_blank" })
  end

  def instruction_for_rdv_to_html(motif)
    auto_link(simple_format(motif.instruction_for_rdv, {}, wrapper_tag: "span"), html: { target: "_blank" })
  end
end
