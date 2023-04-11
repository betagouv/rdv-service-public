# frozen_string_literal: true

class OffDays
  # https://www.service-public.fr/particuliers/vosdroits/F2405
  JOURS_FERIES = [
    Date.new(2023, 1, 1),
    Date.new(2023, 4, 10),
    Date.new(2023, 5, 1),
    Date.new(2023, 5, 8),
    Date.new(2023, 5, 18),
    Date.new(2023, 5, 29),
    Date.new(2023, 7, 14),
    Date.new(2023, 8, 15),
    Date.new(2023, 11, 1),
    Date.new(2023, 11, 11),
    Date.new(2023, 12, 25),

    Date.new(2024, 1, 1),
    Date.new(2024, 4, 1),
    Date.new(2024, 5, 1),
    Date.new(2024, 5, 8),
    Date.new(2024, 5, 9),
    Date.new(2024, 5, 20),
    Date.new(2024, 7, 14),
    Date.new(2024, 8, 15),
    Date.new(2024, 11, 1),
    Date.new(2024, 11, 11),
    Date.new(2024, 12, 25),

    Date.new(2025, 1, 1),
    Date.new(2025, 4, 21),
    Date.new(2025, 5, 1),
    Date.new(2025, 5, 8),
    Date.new(2025, 5, 29),
    Date.new(2025, 6, 9),
    Date.new(2025, 7, 14),
    Date.new(2025, 8, 15),
    Date.new(2025, 11, 1),
    Date.new(2025, 11, 11),
    Date.new(2025, 12, 25),

    Date.new(2026, 1, 1),
    Date.new(2026, 4, 6),
    Date.new(2026, 5, 1),
    Date.new(2026, 5, 8),
    Date.new(2026, 5, 14),
    Date.new(2026, 5, 25),
    Date.new(2026, 7, 14),
    Date.new(2026, 8, 15),
    Date.new(2026, 11, 1),
    Date.new(2026, 11, 11),
    Date.new(2026, 12, 25),
  ].to_set.freeze

  def self.all_in_date_range(date_range)
    return [] if date_range.blank?

    date_range = Lapin::Range.ensure_range_is_date(date_range)

    JOURS_FERIES.intersection(date_range)
  end

  def self.to_full_calendar_array
    JOURS_FERIES.map do |jour_ferie|
      {
        title: "Jour férié 🎉",
        start: jour_ferie.beginning_of_day.as_json,
        end: jour_ferie.end_of_day.as_json,
        backgroundColor: "#6F6F71",
        allDay: true,
        extendedProps: { jour_feries: true },
      }
    end
  end
end
