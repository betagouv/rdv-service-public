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

  def path_to_organisation_selection(params)
    root_path(
      motif_selection(params).merge(
        motif_name_with_location_type: params[:motif_name_with_location_type],
        user_selected_organisation_id: nil
      )
    )
  end

  def path_to_creneau_selection(params)
    root_path(
      motif_selection(params).merge(
        motif_name_with_location_type: params[:motif_name_with_location_type],
        lieu_id: params[:lieu_id], user_selected_organisation_id: params[:user_selected_organisation_id]
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
      public_link_organisation_id: params[:public_link_organisation_id],
    }
  end
end
