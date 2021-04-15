module PlageOuverturesHelper
  def time_collections_for_plage_ouverture
    time_collections_for_hours(7..19)
  end

  def time_collections_for_absence
    time_collections_for_hours(0..23)
  end

  def time_collections_for_hours(hours_range)
    hours_range.flat_map do |h|
      padded_h = format("%02i", h)
      (0..55).step(5).map do |m|
        padded_min = format("%02i", m)
        "#{padded_h}:#{padded_min}"
      end
    end
  end

  def display_recurrence(plage_ouverture)
    every_part = display_every(plage_ouverture)

    time_part = display_time_range(plage_ouverture)

    range_part = display_recurrence_range(plage_ouverture)

    [every_part, time_part, range_part]
  end

  def display_every(plage_ouverture)
    recurrence_hash = plage_ouverture.recurrence.to_hash

    interval = "#{recurrence_hash[:interval]} " if recurrence_hash[:interval]&.>(1)

    case recurrence_hash[:every]
    when :week
      every_part = "Toutes les #{interval} semaines"

      if recurrence_hash[:on].present?
        "#{every_part}, les #{recurrence_hash[:on].map { |d| "#{weekday_in_fr(d)}s" }.to_sentence}"
      else
        "#{every_part}, le #{I18n.l(plage_ouverture.first_day, format: '%A')}"
      end
    when :month
      "Tous les #{interval} mois, #{weekday_position_in_month(recurrence_hash[:day])}"
    end
  end

  def display_time_range(plage_ouverture)
    "de #{I18n.l(plage_ouverture.start_time, format: '%H:%M')} à #{I18n.l(plage_ouverture.end_time, format: '%H:%M')}"
  end

  def plage_ouverture_occurrence_text(plage_ouverture)
    if plage_ouverture.recurring?
      display_recurrence(plage_ouverture).join(" ")
    else
      I18n.l(plage_ouverture.first_day, format: :human) + display_time_range(plage_ouverture)
    end
  end

  def display_recurrence_range(plage_ouverture)
    recurrence_hash = plage_ouverture.recurrence.to_hash

    range_part = "à partir du #{I18n.l(plage_ouverture.first_day, format: :human)}"

    range_part = "#{range_part}, jusqu'au #{I18n.l(recurrence_hash[:until].to_date, format: :human)}" if recurrence_hash[:until].present?
    range_part
  end

  def weekday_position_in_month(day_option)
    nth = day_option.values.first.first
    weekday = day_option.keys.first
    "le #{nth == 1 ? "#{nth}er" : "#{nth}ème"} #{I18n.t('date.day_names')[weekday]}"
  end

  def weekday_in_fr(weekday)
    weekdays = {
      "monday" => "lundi",
      "tuesday" => "mardi",
      "wednesday" => "mercredi",
      "thursday" => "jeudi",
      "friday" => "vendredi",
      "saturday" => "samedi",
      "sunday" => "dimanche",
    }
    weekdays[weekday]
  end

  def po_exceptionnelle_tag(plage_ouverture)
    content_tag(:span, "Exceptionnelle", class: "badge badge-info") if plage_ouverture.exceptionnelle?
  end

  def filter_plage_ouvertures_in_departement_scope(plage_ouvertures)
    Agent::PlageOuverturePolicy::DepartementScope
      .new(pundit_user, PlageOuverture)
      .resolve
      .merge(plage_ouvertures)
  end
end
