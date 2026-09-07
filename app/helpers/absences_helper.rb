module AbsencesHelper
  CALENDAR_BACKGROUND_COLOR = "rgba(52, 57, 58, 0.7)".freeze
  # Équivalent hexadécimal de CALENDAR_BACKGROUND_COLOR (sans transparence), pour les usages qui ne supportent pas le format rgba (ex : input[type=color]).
  CALENDAR_BACKGROUND_COLOR_HEX = "#34393A".freeze

  def absence_tag(absence)
    if absence.expired?
      tag.span("Passée", class: "fr-badge fr-badge--sm fr-mx-1w")
    elsif absence.starts_at.today? || an_ocurrence_after_today?(absence)
      tag.span("En cours", class: "fr-badge fr-badge--info fr-badge--sm fr-badge--no-icon fr-mx-1w")
    end
  end

  def an_ocurrence_after_today?(absence)
    absence.starts_at.past? &&
      absence.recurrence.presence &&
      absence.recurrence.lazy.map(&:to_date).any? { |d| d > Time.zone.now }
  end
end
