class OffDays
  def initialize(date, label)
    @date = date
    @label = label
  end

  attr_reader :date, :label

  # https://www.service-public.fr/particuliers/vosdroits/F2405
  JOURS_FERIES = [
    new(Date.new(2023, 1, 1), "Jour de l'An"),
    new(Date.new(2023, 4, 10), "Lundi de Pâques"),
    new(Date.new(2023, 5, 1), "Journée internationale des travailleurs"),
    new(Date.new(2023, 5, 8), "Victoire 1945"),
    new(Date.new(2023, 5, 18), "Ascension"),
    new(Date.new(2023, 5, 29), "Lundi de Pentecôte"),
    new(Date.new(2023, 7, 14), "Fête nationale"),
    new(Date.new(2023, 8, 15), "Assomption"),
    new(Date.new(2023, 11, 1), "Toussaint"),
    new(Date.new(2023, 11, 11), "Armistice 1918"),
    new(Date.new(2023, 12, 25), "Noël"),

    new(Date.new(2024, 1, 1), "Jour de l'An"),
    new(Date.new(2024, 4, 1), "Lundi de Pâques"),
    new(Date.new(2024, 5, 1), "Journée internationale des travailleurs"),
    new(Date.new(2024, 5, 8), "Victoire 1945"),
    new(Date.new(2024, 5, 9), "Ascension"),
    new(Date.new(2024, 5, 20), "Lundi de Pentecôte"),
    new(Date.new(2024, 7, 14), "Fête nationale"),
    new(Date.new(2024, 8, 15), "Assomption"),
    new(Date.new(2024, 11, 1), "Toussaint"),
    new(Date.new(2024, 11, 11), "Armistice 1918"),
    new(Date.new(2024, 12, 25), "Noël"),

    new(Date.new(2025, 1, 1), "Jour de l'An"),
    new(Date.new(2025, 4, 21), "Lundi de Pâques"),
    new(Date.new(2025, 5, 1), "Journée internationale des travailleurs"),
    new(Date.new(2025, 5, 8), "Victoire 1945"),
    new(Date.new(2025, 5, 29), "Ascension"),
    new(Date.new(2025, 7, 14), "Fête nationale"),
    new(Date.new(2025, 8, 15), "Assomption"),
    new(Date.new(2025, 11, 1), "Toussaint"),
    new(Date.new(2025, 11, 11), "Armistice 1918"),
    new(Date.new(2025, 12, 25), "Noël"),

    new(Date.new(2026, 1, 1), "Jour de l'An"),
    new(Date.new(2026, 4, 6), "Lundi de Pâques"),
    new(Date.new(2026, 5, 1), "Journée internationale des travailleurs"),
    new(Date.new(2026, 5, 8), "Victoire 1945"),
    new(Date.new(2026, 5, 14), "Ascension"),
    new(Date.new(2026, 7, 14), "Fête nationale"),
    new(Date.new(2026, 8, 15), "Assomption"),
    new(Date.new(2026, 11, 1), "Toussaint"),
    new(Date.new(2026, 11, 11), "Armistice 1918"),
    new(Date.new(2026, 12, 25), "Noël"),

    new(Date.new(2027, 1, 1), "Jour de l'An"),
    new(Date.new(2027, 3, 29), "Lundi de Pâques"),
    new(Date.new(2027, 5, 1), "Journée internationale des travailleurs"),
    new(Date.new(2027, 5, 6), "Ascension"),
    new(Date.new(2027, 5, 8), "Victoire 1945"),
    new(Date.new(2027, 7, 14), "Fête nationale"),
    new(Date.new(2027, 8, 15), "Assomption"),
    new(Date.new(2027, 11, 1), "Toussaint"),
    new(Date.new(2027, 11, 11), "Armistice 1918"),
    new(Date.new(2027, 12, 25), "Noël"),
  ].to_set.freeze

  DATES = JOURS_FERIES.map(&:date).to_set.freeze

  FULL_CALENDAR_ARRAY = JOURS_FERIES.map do |jour_ferie|
    {
      title: jour_ferie.label,
      start: jour_ferie.date.beginning_of_day.as_json,
      end: jour_ferie.date.end_of_day.as_json,
      backgroundColor: AbsencesHelper::CALENDAR_BACKGROUND_COLOR,
      textColor: "white",
    }
  end.freeze

  def self.all_in_date_range(date_range)
    return [] if date_range.blank?

    date_range = CreneauxSearch::Range.ensure_range_is_date(date_range)

    DATES.intersection(date_range)
  end

  def self.to_full_calendar_array(agent_ids = nil)
    if agent_ids
      FULL_CALENDAR_ARRAY.map { |day| day.merge(resourceIds: agent_ids) }
    else
      FULL_CALENDAR_ARRAY
    end
  end
end
