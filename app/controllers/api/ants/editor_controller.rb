# frozen_string_literal: true

class Api::Ants::EditorController < Api::Ants::BaseController
  before_action :check_required_params!, only: [:available_time_slots]

  def get_managed_meeting_points # rubocop:disable Naming/AccessorMethodName
    render json: lieux.map { |lieu| lieu_infos(lieu) }
  end

  def available_time_slots
    render json: lieux.where(id: params[:meeting_point_ids]).to_h { |lieu| [lieu.id, time_slots(lieu)] }
  end

  private

  def lieux
    Lieu.joins(:organisation).where(organisations: { verticale: :rdv_mairie })
  end

  def time_slots(lieu)
    creneaux(lieu).map do |creneau|
      {
        datetime: creneau.starts_at.strftime("%Y-%m-%dT%H:%MZ"),
        callback_url: creneaux_url(
          starts_at: creneau.starts_at.strftime("%Y-%m-%d %H:%M"),
          lieu_id: lieu.id,
          motif_id: motif.id
        ),
      }
    end
  end

  def creneaux(lieu)
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

  def motif
    @motif ||= lieux.first.organisation.motifs.first
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

  def check_required_params!
    params.require(:meeting_point_ids)
    params.require(:start_date)
    params.require(:end_date)
  end
end
