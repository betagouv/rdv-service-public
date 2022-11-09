# frozen_string_literal: true

module SearchContextHelper
  def path_to_motif_selection(params)
    root_path(motif_selection(params))
  end

  def path_to_lieu_selection(params)
    root_path(
      motif_selection(params).merge(
        motif_name_with_location_type: params[:motif_name_with_location_type]
      )
    )
  end

  def path_to_creneau_selection(params)
    root_path(
      motif_selection(params).merge(
        motif_name_with_location_type: params[:motif_name_with_location_type],
        lieu_id: params[:lieu_id]
      )
    )
  end

  private

  def motif_selection(params)
    {
      departement: params[:departement],
      city_code: params[:city_code],
      longitude: params[:longitude],
      latitude: params[:latitude],
      street_ban_id: params[:street_ban_id],
      address: params[:address],
      service_id: params[:service_id],
      organisation_id: params[:organisation_id],
    }
  end
end
