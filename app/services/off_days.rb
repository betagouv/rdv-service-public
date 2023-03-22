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
  ].to_set.freeze

  # This reminder will be triggered on server startup
  Sentry.capture_message("Il faut mettre à jour la liste des jours fériés pour 2024") if Time.zone.today.year > 2023

  def self.all_in_date_range(date_range)
    return [] if date_range.blank?

    date_range = Lapin::Range.ensure_range_is_date(date_range)

    JOURS_FERIES.intersection(date_range)
  end

  def self.to_a
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
