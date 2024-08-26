class Api::Visioplainte::CreneauxController < Api::Visioplainte::BaseController
  def index
    render json: {
      creneaux: [
        {
          starts_at: "2024-12-22T10:00:00+02:00",
          duration_in_min: 30,
        },
        {
          starts_at: "2024-12-22T10:30:00+02:00",
          duration_in_min: 30,
        },
        {
          starts_at: "2024-12-22T11:00:00+02:00",
          duration_in_min: 30,
        },
      ],
    }
  end

  def prochain
    # Une fausse implémentation pour la documentation
    if params[:service] == "Gendarmerie"
      error = {
        erreur: "Aucun créneau n'est disponible après cette date pour ce service.",
      }
      render(json: error, status: :not_found) and return
    end

    render json: {
      starts_at: "2024-12-22T10:00:00+02:00",
      duration_in_min: 30,
    }
  end
end
