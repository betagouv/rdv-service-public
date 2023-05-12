# frozen_string_literal: true

class Api::Ants::EditorController < Api::Ants::BaseController
  def get_managed_meeting_points # rubocop:disable Naming/AccessorMethodName
    render json: [].to_json
  end

  def available_time_slots
    response_hash = {}

    lieux.each do |lieu|
      response_hash[lieu.id] = creneaux(
        lieu,
        Date.parse(params[:start_date]),
        Date.parse(params[:end_date])
      ).map do |creneau|
        { datetime: creneau.starts_at }
      end
    end

    render json: response_hash
  end

  private

  def lieux
    @lieux ||= Lieu.joins(:organisation).where(organisations: { verticale: :rdv_mairie })
      .where(id: params[:meeting_point_ids])
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
