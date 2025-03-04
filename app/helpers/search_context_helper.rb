module SearchContextHelper
  def path_to_motif_selection(params)
    prendre_rdv_path(
      service_selection(params).merge(
        service_id: params[:service_id]
      )
    )
  end

  def path_to_service_selection(params)
    prendre_rdv_path(service_selection(params))
  end

  def path_to_lieu_selection(params)
    prendre_rdv_path(
      service_selection(params).merge(
        motif_name_with_location_type: params[:motif_name_with_location_type],
        service_id: params[:service_id]
      )
    )
  end

  def path_to_organisation_selection(params)
    prendre_rdv_path(
      service_selection(params).merge(
        motif_name_with_location_type: params[:motif_name_with_location_type],
        user_selected_organisation_id: nil
      )
    )
  end

  def path_to_creneau_selection(params)
    prendre_rdv_path(
      service_selection(params).merge(
        motif_name_with_location_type: params[:motif_name_with_location_type],
        lieu_id: params[:lieu_id], user_selected_organisation_id: params[:user_selected_organisation_id]
      )
    )
  end

  private

  def service_selection(params)
    permit_hash_or_params(params, service_selection_permitted_params_list)
  end

  def permit_hash_or_params(hash_or_params, permitted_params_list)
    params = if hash_or_params.is_a?(Hash)
               ActionController::Parameters.new(hash_or_params)
             else
               hash_or_params
             end

    params.permit(*permitted_params_list)
  end

  def service_selection_permitted_params_list
    [
      :departement,
      :city_code,
      :longitude,
      :latitude,
      :street_ban_id,
      :address,
      :public_link_organisation_id,
      :prescripteur,
      :duration,
      {
        referent_ids: [],
        external_organisation_ids: [],
        user_ids: [],
      },
    ]
  end
end
