class JoursFeriesService
  # https://demarchesadministratives.fr/actualites/calendrier-des-jours-feries-2019-2020-2021
  JOURS_FERIES_2020 = [
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
  ].freeze

  JOURS_FERIES_2021 = [
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
  ].freeze

  def self.all_in_date_range(date_range)
    date_range.select do |d|
      if d.year == 2020
        d.in?(JOURS_FERIES_2020)
      elsif d.year == 2021
        d.in?(JOURS_FERIES_2021)
      end
    end
  end
end
