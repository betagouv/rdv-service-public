module PlageOuverturesHelper
  def time_collections
    (7..19).flat_map do |h|
      padded_h = format("%02i", h)
      (0..55).step(5).map do |m|
        padded_min = format("%02i", m)
        "#{padded_h}:#{padded_min}"
      end
    end
  end

  def recurrence_collection(day)
    [
      ["Jamais", Montrose.daily(total: 1).to_json],
      ["Toutes les semaines le #{I18n.l(day, format: "%A")}", Montrose.weekly.to_json, { id: "weekly" }],
      ["Toutes les 2 semaines le #{I18n.l(day, format: "%A")}", Montrose.every(2.weeks).to_json, { id: "weekly_by_2" }],
    ]
  end

  def recurrence_to_human(plage_ouverture)
    hours = "de #{l(plage_ouverture.start_at, format: "%H:%M")} à #{l(plage_ouverture.end_at, format: "%H:%M")}"
    case plage_ouverture.recurrence.to_json
    when Montrose.daily(total: 1).to_json
      "Le #{I18n.l(plage_ouverture.first_day, format: "%A %d %B %Y")} #{hours}"
    when Montrose.weekly.to_json
      "Toutes les semaines le #{I18n.l(plage_ouverture.first_day, format: "%A")} #{hours}"
    when Montrose.every(2.weeks).to_json
      "Toutes les 2 semaines le #{I18n.l(plage_ouverture.first_day, format: "%A")} #{hours}"
    end
  end
end
