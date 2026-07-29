module Search::LogParamsConcern
  extend ActiveSupport::Concern

  # on recopie ici plutôt que de référencer les constantes pour éviter que
  # des futurs ajouts potentiellement sensibles soient automatiquement loggés
  LOGGABLE_SEARCH_PARAMS = (
    # from WebSearchContext::ADDRESS_SELECTION_PARAMS
    %i[latitude longitude address city_code street_ban_id departement] +
    # from WebSearchContext::USER_CHOICE_PARAMS
    %i[service_id motif_name_with_location_type lieu_id user_selected_organisation_id motif_id ants_pre_demandes_count] +
    # from SearchController#search_params
    %i[motif_category_short_name date public_link_organisation_id prescripteur organisation_ids external_organisation_ids]
  ).freeze

  # méthode automatiquement appelée par lograge cf https://github.com/roidrage/lograge/#installation
  def append_info_to_payload(payload)
    super
    return unless action_name == "search_rdv" # uniquement pour la recherche GET

    payload[:search_params] = params.slice(*LOGGABLE_SEARCH_PARAMS).to_unsafe_h.compact_blank
    payload[:user_agent] = request.user_agent
  end
end
