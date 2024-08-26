class Api::Visioplainte::CreneauxController < Api::Visioplainte::BaseController
  before_action :validate_date_range, only: [:index]
  def index
    motif = find_motif(params[:service])

    render json: {
      creneaux: creneaux(motif).map do |creneau|
        {
          starts_at: creneau.starts_at.iso8601,
          duration_in_min: motif.default_duration_in_min,
        }
      end,
    }
  end

  def prochain
    # Une fausse implémentation pour la documentation
    if params[:service] == "Gendarmerie"
      errors = ["Aucun créneau n'est disponible après cette date pour ce service."]

      render(json: { errors: errors }, status: :not_found) and return
    end

    render json: {
      starts_at: "2024-12-22T10:00:00+02:00",
      duration_in_min: 30,
    }
  end

  private

  def validate_date_range
    errors = []

    if params[:date_debut].blank?
      errors << "Paramètre date_debut manquant"
    end

    if params[:date_fin].blank?
      errors << "Paramètre date_fin manquant"
    end

    if errors.empty? && (date_range.last - date_range.first).to_i > 31
      errors << "date_debut et date_fin ne doivent pas être espacés de plus de 31 jours"
    end

    if errors.any?
      render(json: { errors: errors }, status: :bad_request) and return
    end
  end

  def date_range
    @date_range ||= (Date.parse(params[:date_debut])..Date.parse(params[:date_fin]))
  end

  def creneaux(motif)
    Users::CreneauxSearch.new(
      lieu: nil,
      user: nil,
      motif: motif,
      date_range: date_range
    ).creneaux
  end

  def find_motif(_service)
    motifs = Motif.joins(organisation: :territory).where(territories: { name: Territory::VISIOPLAINTE_NAME })

    motifs.joins(:service).find_by(service: { name: service_names[params["service"]] })
  end

  def service_names
    {
      "Police" => "Police Nationale",
      "Gendarmerie" => "Gendarmerie Nationale",
    }
  end
end
