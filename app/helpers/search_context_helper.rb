module SearchContextHelper
  def path_to_service_selection(params)
    prendre_rdv_path_with_filtered_params(
      params,
      starting_permitted_params_list
    )
  end

  def path_to_motif_selection(params)
    prendre_rdv_path_with_filtered_params(
      params,
      [:service_id] + starting_permitted_params_list
    )
  end

  def path_to_ants_pre_demandes_count_selection(params)
    prendre_rdv_path_with_filtered_params(
      params,
      %i[service_id motif_name_with_location_type] + starting_permitted_params_list
    )
  end

  def path_to_lieu_selection(params)
    prendre_rdv_path_with_filtered_params(
      params,
      %i[service_id motif_name_with_location_type ants_pre_demandes_count] + starting_permitted_params_list
    )
  end

  # C'est la même implémentation que #path_to_lieu_selection, et c'est en fonction des motifs disponibles
  # que la logique de Users::CreneauxWizardConcern#current_step décidera entre lieu_selection et organisation_selection
  def path_to_organisation_selection(params)
    prendre_rdv_path_with_filtered_params(
      params,
      %i[service_id motif_name_with_location_type ants_pre_demandes_count] + starting_permitted_params_list
    )
  end

  def path_to_creneau_selection(params)
    additional_params = %i[
      service_id motif_name_with_location_type ants_pre_demandes_count lieu_id user_selected_organisation_id
    ]

    prendre_rdv_path_with_filtered_params(
      params,
      additional_params + starting_permitted_params_list
    )
  end

  private

  def prendre_rdv_path_with_filtered_params(params, permitted_params_list)
    prendre_rdv_path(permit_hash_or_params(params, permitted_params_list))
  end

  def permit_hash_or_params(hash_or_params, permitted_params_list)
    params = if hash_or_params.is_a?(Hash)
               ActionController::Parameters.new(hash_or_params)
             else
               hash_or_params
             end

    params.permit(*permitted_params_list)
  end

  def starting_permitted_params_list
    [
      *WebSearchContext::ADDRESS_SELECTION_PARAMS,
      :public_link_organisation_id,
      :prescripteur,
      :duration,
      {
        referent_ids: [],
        external_organisation_ids: [],
        user_ids: [], # utilisés par les agents prescripteurs en prescription interne
      },
    ]
  end
end
