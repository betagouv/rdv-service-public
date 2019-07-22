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
      ["Jamais", PlageOuverture::RECURRENCES[:never]],
      ["Toutes les semaines le #{l(day, format: "%A")}", PlageOuverture::RECURRENCES[:weekly], { id: "weekly" }],
      ["Toutes les 2 semaines le #{l(day, format: "%A")}", PlageOuverture::RECURRENCES[:weekly_by_2], { id: "weekly_by_2" }],
    ]
  end

  def recurrence_to_human(plage_ouverture)
    hours_range = "de #{l(plage_ouverture.start_at, format: "%H:%M")} à #{l(plage_ouverture.end_at, format: "%H:%M")}"

    case plage_ouverture.recurrence.to_json
    when PlageOuverture::RECURRENCES[:never]
      "Le #{l(plage_ouverture.first_day, format: "%A %d %B %Y")} #{hours_range}"
    when PlageOuverture::RECURRENCES[:weekly]
      "Toutes les semaines le #{l(plage_ouverture.first_day, format: "%A")} #{hours_range}"
    when PlageOuverture::RECURRENCES[:weekly_by_2]
      "Toutes les 2 semaines le #{l(plage_ouverture.first_day, format: "%A")} #{hours_range}"
    end
  end

  def po_exceptionnelle_tag(plage_ouverture)
    content_tag(:span, 'Exceptionnelle', class: 'badge badge-info') if plage_ouverture.exceptionnelle?
  end
end
