module RecurrenceHelper
  def display_recurrence(recurrent_record)
    every_part = display_every(recurrent_record)

    time_part = display_time_range(recurrent_record)

    range_part = display_recurrence_range(recurrent_record)

    [every_part, time_part, range_part]
  end

  def display_every(recurrent_record)
    recurrence_hash = recurrent_record.recurrence.to_hash

    interval = "#{recurrence_hash[:interval]} " if recurrence_hash[:interval]&.>(1)

    case recurrence_hash[:every]
    when :week
      every_part = "Toutes les #{interval} semaines"

      if recurrence_hash[:on].present?
        "#{every_part}, les #{recurrence_hash[:on].map { |d| "#{weekday_in_fr(d)}s" }.to_sentence}"
      else
        "#{every_part}, le #{I18n.l(recurrent_record.first_day, format: '%A')}"
      end
    when :month
      "Tous les #{interval} mois, #{weekday_position_in_month(recurrence_hash[:day])}"
    end
  end

  def display_time_range(recurrent_record)
    str = "de #{I18n.l(recurrent_record.start_time, format: '%H:%M')} à #{I18n.l(recurrent_record.end_time, format: '%H:%M')}"
    if recurrent_record.try(:secondary_start_time) && recurrent_record.try(:secondary_end_time)
      str += " et de #{I18n.l(recurrent_record.secondary_start_time, format: '%H:%M')} à #{I18n.l(recurrent_record.secondary_end_time, format: '%H:%M')}"
    end
    str
  end

  def occurrence_text(recurrent_record)
    if recurrent_record.recurring?
      display_recurrence(recurrent_record).join(" ")
    else
      [I18n.l(recurrent_record.first_day, format: :human), display_time_range(recurrent_record)].join(" ")
    end
  end

  def display_recurrence_range(recurrent_record)
    recurrence_hash = recurrent_record.recurrence.to_hash

    range_part = "à partir du #{I18n.l(recurrent_record.first_day, format: :human)}"

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

  def exceptionnelle_tag(recurrent_record)
    tag.span("Exceptionnelle", class: "fr-badge fr-badge--sm fr-badge--green-archipel") if recurrent_record.exceptionnelle?
  end

  def filter_plage_ouvertures_in_departement_scope(plage_ouvertures)
    Agent::PlageOuverturePolicy::Scope
      .new(pundit_user, PlageOuverture)
      .resolve
      .merge(plage_ouvertures)
  end
end
