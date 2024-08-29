class Api::Visioplainte::CreneauxController < Api::Visioplainte::BaseController
  before_action :validate_date_debut_and_service
  before_action :validate_date_range, only: [:index]

  SERVICE_NAMES = {
    "Police" => "Police Nationale",
    "Gendarmerie" => "Gendarmerie Nationale",
  }.freeze

  def index
    creneaux = Users::CreneauxSearch.new(
      motif: motif,
      date_range: date_range
    ).creneaux

    render json: {
      creneaux: creneaux.map do |creneau|
        creneau_to_hash(creneau)
      end,
    }
  end

  def prochain
    date_debut = Date.parse(params[:date_debut])
    date_range = date_debut..(date_debut + 60.days)

    next_availability = Users::CreneauxSearch.new(
      motif: motif,
      date_range: date_range
    ).next_availability

    if next_availability
      render json: creneau_to_hash(next_availability)
    else
      errors = ["Aucun créneau n'est disponible après cette date pour ce service."]

      render(json: { errors: errors }, status: :not_found) and return
    end
  end

  def self.find_motif(service_param)
    Motif.joins(organisation: :territory).where(territories: { name: Territory::VISIOPLAINTE_NAME })
      .joins(:service).find_by(service: { name: SERVICE_NAMES[service_param] })
  end

  private

  def motif
    @motif ||= self.class.find_motif(params[:service])
  end

  def creneau_to_hash(creneau)
    {
      starts_at: creneau.starts_at.iso8601,
      duration_in_min: motif.default_duration_in_min,
    }
  end

  def validate_date_debut_and_service
    errors = []

    unless params[:service].in?(SERVICE_NAMES.keys)
      errors << "Le paramètre service doit avoir pour valeur 'Police' ou 'Gendarmerie'"
    end

    if params[:date_debut].blank?
      errors << "Paramètre date_debut manquant"
    end

    if errors.any?
      render(json: { errors: errors }, status: :bad_request) and return
    end
  end

  def validate_date_range
    errors = []

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
end
