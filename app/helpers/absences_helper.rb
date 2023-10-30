module AbsencesHelper
  def absence_tag(absence)
    if absence.expired?
      tag.span("Passée", class: "badge badge-light")
    elsif absence.starts_at.today? || an_ocurrence_after_today?(absence)
      tag.span("En cours", class: "badge badge-info")
    end
  end

  def an_ocurrence_after_today?(absence)
    absence.starts_at.past? &&
      absence.recurrence.presence &&
      absence.recurrence.lazy.map(&:to_date).any? { |d| d > Time.zone.now }
  end
end
