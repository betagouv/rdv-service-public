# frozen_string_literal: true

module SearchContextHelper
  PARAMS_FOR_MOTIF_SELECTION = %i[
    departement
    city_code
    street_ban_id
    address
    service_id
    organisation_id
  ] + SearchContext::ATTRIBUTES_FOR_MOTIF_SELECTION

  # Step 2
  PARAMS_FOR_LIEU_SELECTION = PARAMS_FOR_MOTIF_SELECTION + [:motif_name_with_location_type]

  # Step 3
  PARAMS_FOR_CRENEAUX_SELECTION = PARAMS_FOR_LIEU_SELECTION + [:lieu_id]

  def path_to_motif_selection(params)
    root_path(params.slice(*PARAMS_FOR_MOTIF_SELECTION))
  end

  def path_to_lieu_selection(params)
    root_path(params.slice(*PARAMS_FOR_LIEU_SELECTION))
  end

  def path_to_creneau_selection(params)
    root_path(params.slice(*PARAMS_FOR_CRENEAUX_SELECTION))
  end
end
