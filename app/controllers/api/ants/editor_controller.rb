# frozen_string_literal: true

class Api::Ants::EditorController < Api::Ants::BaseController
  def get_managed_meeting_points # rubocop:disable Naming/AccessorMethodName
    response_body = lieux.map do |lieu|
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

    render json: response_body
  end

  def available_time_slots
    response_hash = {}

    lieux.where(id: params[:meeting_point_ids]).each do |lieu|
      response_hash[lieu.id] = creneaux(
        lieu,
        Date.parse(params[:start_date]),
        Date.parse(params[:end_date])
      ).map do |creneau|
        { datetime: creneau.starts_at.strftime("%Y-%m-%dT%H:%MZ") }
      end
    end

    render json: response_hash
  end

  private

  def lieux
    @lieux ||= Lieu.joins(:organisation).where(organisations: { verticale: :rdv_mairie })
  end

  def creneaux(lieu, start_date, end_date)
    motif = lieu.organisation.motifs.first

    Users::CreneauxSearch.new(
      user: @current_user,
      motif: motif,
      lieu: lieu,
      date_range: (start_date..end_date)
    ).creneaux
  end
end
