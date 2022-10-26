# frozen_string_literal: true

# Ce check a été ajouté pour éviter d'inexplicables saisies
# accidentelles, par exemple 1922 au lieu de 2022.
# Voir : https://github.com/betagouv/rdv-solidarites.fr/issues/2914
module EnsuresRealisticDate
  extend ActiveSupport::Concern

  included do
    validate :date_is_realistic
  end

  private

  def date_is_realistic
    return unless first_day

    if first_day > 5.years.from_now
      errors.add(:base, "Le premier jour ne peut pas être loin dans le futur.")
    end

    if first_day.year < 2018
      errors.add(:base, "Le premier jour ne peut pas être loin dans le passé.")
    end
  end
end
