# frozen_string_literal: true

module SearchContextHelper
  def path_to_motif_selection(params)
    root_path(params.permit(motif_selection_attributes))
  end

  def path_to_lieu_selection(params)
    attributes = motif_selection_attributes + [:motif_name_with_location_type]
    root_path(params.permit(*attributes))
  end

  def path_to_creneau_selection(params)
    attributes = motif_selection_attributes + %i[motif_name_with_location_type lieu_id]
    root_path(params.permit(*attributes))
  end

  private

  def motif_selection_attributes
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
