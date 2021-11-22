# frozen_string_literal: true

class ExternalInvitations::MotifsController < ExternalInvitations::BaseController
  def index
    # if no motif can be found through the geo search we retrieve all orga motifs for the service
    @available_motifs = \
      @geo_search.available_motifs.where(organisation: @organisation).presence ||
      Motif.available_with_plages_ouvertures_for_organisation(@organisation)

    @unique_motifs_by_name_and_location_type = @available_motifs
      .where(service: @service)
      .uniq { [_1.name, _1.location_type] }
  end
end
