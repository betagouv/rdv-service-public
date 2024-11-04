# voir docs/interconnexions/ants.md
class Api::Ants::EditorController < Api::Ants::BaseController
  def get_managed_meeting_points # rubocop:disable Naming/AccessorMethodName
    render(json: self.class.lieux.map { |lieu| lieu_infos(lieu) })
  end

  def available_time_slots
    params.require(%i[meeting_point_ids start_date end_date reason])

    unless params[:reason].in?(ANTS_MOTIF_CATEGORY_IDS_TO_NAMES.keys)
      Sentry.capture_message("ANTS provided invalid reason: #{params[:reason].inspect}", fingerprint: ["ants_invalid_reason"])
      render status: :bad_request, json: { error: { code: 400, message: "Invalid reason param" } }
      return
    end

    if params[:start_date] > params[:end_date]
      render status: :bad_request, json: { error: { code: 400, message: "start_date is after end_date" } }
      return
    end

    time_slots_search = TimeSlotsSearch.new(
      meeting_point_ids: request.query_string.scan(/meeting_point_ids=(\d+)/).flatten,
      # On ne peut pas utiliser params[:meeting_point_ids] car l'ants passe une liste de paramètres sans crochets.
      # Autrement dit, ils utilisent la syntaxe meeting_point_ids=1&meeting_point_ids=2 pour envoyer un tableau d'ids
      date_range: (Date.parse(params[:start_date])..Date.parse(params[:end_date])),
      users_count: params.fetch(:documents_number, 1).to_i,
      reason: params[:reason],
      host: URI.parse(request.url).host # Nécessaire pour générer les URLs depuis TimeSlotsSearch
    )
    render json: time_slots_search.time_slots_by_lieu_id
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

  def self.lieux
    Lieu.joins(:organisation)
      .where(organisations: { territory_id: Territory.mairies&.id })
  end

  private

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

  class TimeSlotsSearch
    attr_reader :meeting_point_ids, :date_range, :reason, :users_count, :host

    def initialize(meeting_point_ids:, date_range:, reason:, users_count:, host:)
      @meeting_point_ids = meeting_point_ids
      @date_range = date_range
      @reason = reason
      @users_count = users_count
      @host = host
    end

    def time_slots_by_lieu_id
      Api::Ants::EditorController
        .lieux
        .where(id: meeting_point_ids)
        .to_h { |lieu| [lieu.id, time_slots_for_lieu(lieu)] }
    end

    private

    def time_slots_for_lieu(lieu)
      Motif
        .where(organisation_id: lieu.organisation_id, motif_category_id:)
        .map { |motif| time_slots_for_lieu_and_motif(lieu:, motif:) }
        .flatten
        .uniq { _1[:datetime] }
        .sort_by { _1[:datetime] }
    end

    def time_slots_for_lieu_and_motif(lieu:, motif:)
      # on change en mémoire, la durée par défaut du motif pour rechercher des créneaux
      # d'une durée adaptée au nombre de participants au Rdv
      motif.default_duration_in_min *= users_count
      CreneauxSearch::ForUser.new(lieu:, motif:, date_range:)
        .creneaux
        .map { creneau_to_time_slot(_1) }
        .uniq
    end

    def motif_category_id
      @motif_category_id ||= MotifCategory
        .find_by(name: Api::Ants::EditorController::ANTS_MOTIF_CATEGORY_IDS_TO_NAMES[reason])
        .id
    end

    def creneau_to_time_slot(creneau)
      {
        datetime: creneau.starts_at.strftime("%Y-%m-%dT%H:%MZ"),
        callback_url: Rails.application.routes.url_helpers.creneaux_url(
          host:,
          starts_at: creneau.starts_at.strftime("%Y-%m-%d %H:%M"),
          lieu_id: creneau.lieu_id,
          motif_id: creneau.motif.id,
          public_link_organisation_id: creneau.motif.organisation_id,
          duration: creneau.motif.default_duration_in_min
        ),
      }
    end
  end
end
