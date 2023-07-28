# frozen_string_literal: true

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

  CNI_MOTIF_CATEGORY_NAME = "Carte d'identité disponible sur le site de l'ANTS"
  PASSPORT_MOTIF_CATEGORY_NAME = "Passeport disponible sur le site de l'ANTS"
  CNI_AND_PASSPORT_MOTIF_CATEGORY_NAME = "Carte d'identité et passeport disponible sur le site de l'ANTS"

  private

  def lieux
    Lieu.joins(:organisation).where(organisations: { verticale: :rdv_mairie })
  end

  def time_slots(lieu, reason)
    motifs(lieu, reason).map do |motif|
      creneaux(lieu, motif).map do |creneau|
        {
          datetime: creneau.starts_at.strftime("%Y-%m-%dT%H:%MZ"),
          callback_url: creneaux_url(
            starts_at: creneau.starts_at.strftime("%Y-%m-%d %H:%M"),
            lieu_id: lieu.id,
            motif_id: motif.id,
            public_link_organisation_id: lieu.organisation.id
          ),
        }
      end
    end.flatten
  end

  def creneaux(lieu, motif)
    motif.default_duration_in_min = motif.default_duration_in_min * users_count

    Users::CreneauxSearch.new(
      lieu: lieu,
      user: @current_user,
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
    motif_category_name = {
      "CNI" => CNI_MOTIF_CATEGORY_NAME,
      "PASSPORT" => PASSPORT_MOTIF_CATEGORY_NAME,
      "CNI-PASSPORT" => CNI_AND_PASSPORT_MOTIF_CATEGORY_NAME,
    }[reason]

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

  def users_count
    (params[:documents_number] || 1).to_i
  end

  def check_required_params!
    params.require(:meeting_point_ids)
    params.require(:start_date)
    params.require(:end_date)
    params.require(:reason)
  end
end
