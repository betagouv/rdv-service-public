# voir docs/interconnexions/ants.md
class Api::Ants::EditorController < Api::Ants::BaseController
  before_action :check_required_params!, only: [:available_time_slots]

  def get_managed_meeting_points # rubocop:disable Naming/AccessorMethodName
    render json: lieux.map { |lieu| lieu_infos(lieu) }
  end

  def available_time_slots
    # On ne peut pas utiliser params[:meeting_point_ids] car l'ants passe une liste de paramètres sans crochets.
    # Autrement dit, ils utilisent la syntaxe meeting_point_ids=1&meeting_point_ids=2 pour envoyer un tableau d'ids
    meeting_point_ids = request.query_string.scan(/meeting_point_ids=(\d+)/).flatten

    render json: lieux.where(id: meeting_point_ids).to_h { |lieu| [lieu.id, time_slots(lieu, params[:reason])] }
  end

  def search_application_ids
    # On ne peut pas utiliser params[:application_ids] car l'ants passe une liste de paramètres sans crochets.
    # Autrement dit, ils utilisent la syntaxe application_ids=1&application_ids=2 pour envoyer un tableau d'ids
    application_ids = request.query_string.scan(/application_ids=(\d+)/).flatten

    render json: application_ids.index_with { |_application_id| [] }
  end

  ANTS_MOTIF_CATEGORY_NAMES = [
    CNI_MOTIF_CATEGORY_NAME = "Carte d'identité disponible sur le site de l'ANTS".freeze,
    PASSPORT_MOTIF_CATEGORY_NAME = "Passeport disponible sur le site de l'ANTS".freeze,
    CNI_AND_PASSPORT_MOTIF_CATEGORY_NAME = "Carte d'identité et passeport disponible sur le site de l'ANTS".freeze,
  ].freeze

  ANTS_MOTIF_CATEGORY_IDS_TO_NAMES = {
    "CNI" => CNI_MOTIF_CATEGORY_NAME,
    "PASSPORT" => PASSPORT_MOTIF_CATEGORY_NAME,
    "CNI-PASSPORT" => CNI_AND_PASSPORT_MOTIF_CATEGORY_NAME,
  }.freeze

  private

  def lieux
    Lieu.joins(:organisation).where(organisations: { territory_id: Territory.mairies&.id })
  end

  def time_slots(lieu, reason)
    creneaux = motifs(lieu, reason).map do |motif|
      motif.default_duration_in_min = rdv_duration(motif)
      motif_creneaux = creneaux(lieu, motif)
      motif_creneaux.map { |creneau| time_slot_data(creneau) }.uniq
    end

    creneaux.flatten.uniq { _1[:datetime] }.sort_by { _1[:datetime] }
  end

  def creneaux(lieu, motif)
    CreneauxSearch::ForUser.new(
      lieu: lieu,
      motif: motif,
      date_range: date_range
    ).creneaux
  end

  def date_range
    @date_range ||= (Date.parse(params[:start_date])..Date.parse(params[:end_date]))
  end

  def motifs(lieu, reason)
    lieu.organisation.motifs.where(motif_category_id: reason_to_motif_category_id(reason))
  end

  def reason_to_motif_category_id(reason)
    motif_category_name = ANTS_MOTIF_CATEGORY_IDS_TO_NAMES[reason]
    MotifCategory.find_by(name: motif_category_name).id
  end

  def lieu_infos(lieu)
    public_entry_address, city_name, zip_code = lieu.address.split(", ")

    {
      id: lieu.id.to_s,
      name: lieu.name,
      longitude: lieu.longitude,
      latitude: lieu.latitude,
      public_entry_address: public_entry_address,
      zip_code: zip_code,
      city_name: city_name,
    }
  end

  # Cette méthode change en mémoire, la durée par défaut du motif
  # Cela permet de rechercher des créneaux d'une durée adaptée au nombre de participants au Rdv
  def rdv_duration(motif)
    users_count = params.fetch(:documents_number, 1).to_i
    motif.default_duration_in_min * users_count
  end

  def check_required_params!
    params.require(:meeting_point_ids)
    params.require(:start_date)
    params.require(:end_date)
    params.require(:reason)

    unless params[:reason].in?(ANTS_MOTIF_CATEGORY_IDS_TO_NAMES.keys)
      Sentry.capture_message("ANTS provided invalid reason: #{params[:reason].inspect}", fingerprint: ["ants_invalid_reason"])
      render status: :bad_request, json: { error: { code: 400, message: "Invalid reason param" } }
    end

    if params[:start_date] > params[:end_date]
      render status: :bad_request, json: { error: { code: 400, message: "start_date is after end_date" } }
    end
  end

  def time_slot_data(creneau)
    {
      datetime: creneau.starts_at.strftime("%Y-%m-%dT%H:%MZ"),
      callback_url: time_slot_url(creneau),
    }
  end

  def time_slot_url(creneau)
    creneaux_url(
      starts_at: creneau.starts_at.strftime("%Y-%m-%d %H:%M"),
      lieu_id: creneau.lieu.id,
      motif_id: creneau.motif.id,
      public_link_organisation_id: creneau.lieu.organisation.id,
      duration: creneau.motif.default_duration_in_min
    )
  end
end
