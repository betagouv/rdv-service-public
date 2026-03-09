module CreneauxSearch::Calculator
  class CreneauRangesFromPlageOuverture
    def initialize(plages_ouvetures, search_datetime_range, work_on_off_days:)
      @plages_ouvetures = plages_ouvetures
      @search_datetime_range = search_datetime_range
      @work_on_off_days = work_on_off_days
    end

    def creneaux_ranges
      # pseudo-code :
      # charger toutes les occurrences de la plage_ouverture
      #
      # si applicable, supprimer celles pendant les jours fériés et dimanches
      #
      # charger les absences sur le range et calculer leurs occurrences
      #
      # faire une tsmultirange soustraction pour les absences
      #
      # charger les occurrences de agentsrdvs concernés
      # faire une tsmultirange soustraction sur le résultat pour les agentsrdvs
      #
      # idem pour les indispos caldav
      #
      # découper le range résultant en créneaux
    end
  end
end
