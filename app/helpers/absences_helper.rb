module AbsencesHelper
  def absence_tag(absence)
    if absence.in_progress?
      content_tag(:span, "En cours", class: "badge badge-info")
    elsif absence.starts_at.past?
      content_tag(:span, "Passée", class: "badge badge-light")
    end
  end
end
