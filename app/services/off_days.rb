# frozen_string_literal: true

class OffDays
  # https://www.service-public.fr/particuliers/vosdroits/F2405
  JOURS_FERIES = [
    Date.new(2020, 1, 1),
    Date.new(2020, 4, 13),
    Date.new(2020, 5, 1),
    Date.new(2020, 5, 8),
    Date.new(2020, 5, 21),
    Date.new(2020, 6, 1),
    Date.new(2020, 7, 14),
    Date.new(2020, 8, 15),
    Date.new(2020, 11, 1),
    Date.new(2020, 11, 11),
    Date.new(2020, 12, 25),

    Date.new(2021, 1, 1),
    Date.new(2021, 4, 5),
    Date.new(2021, 5, 1),
    Date.new(2021, 5, 8),
    Date.new(2021, 5, 13),
    Date.new(2021, 5, 24),
    Date.new(2021, 7, 14),
    Date.new(2021, 8, 15),
    Date.new(2021, 11, 1),
    Date.new(2021, 11, 11),
    Date.new(2021, 12, 25),

    Date.new(2022, 1, 1),
    Date.new(2022, 4, 18),
    Date.new(2022, 5, 1),
    Date.new(2022, 5, 8),
    Date.new(2022, 5, 26),
    Date.new(2022, 6, 6),
    Date.new(2022, 7, 14),
    Date.new(2022, 8, 15),
    Date.new(2022, 11, 1),
    Date.new(2022, 11, 11),
    Date.new(2022, 12, 25),

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
end
