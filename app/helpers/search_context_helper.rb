# frozen_string_literal: true

module SearchContextHelper
  def path_to_motif_selection(params)
    root_path(params.slice(motif_selection_params))
  end

  def path_to_lieu_selection(params)
    attributes = motif_selection_params + [:motif_name_with_location_type]
    root_path(params.slice(*attributes))
  end

  def path_to_creneau_selection(params)
    attributes = motif_selection_params + %i[motif_name_with_location_type lieu_id]
    root_path(params.slice(*attributes))
  end

  private

  def motif_selection_params
    %i[
      departement
      city_code
      longitude
      latitude
      street_ban_id
      address
      service_id
      organisation_id
    ]
  end
end
