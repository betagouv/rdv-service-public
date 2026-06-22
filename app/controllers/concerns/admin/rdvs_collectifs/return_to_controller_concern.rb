# Lorsqu'un agent part d'une fiche usager pour chercher un créneau de RDV collectif et y
# inscrire l'usager, on a envie de rediriger l'agent vers la recherche de créneaux scopée
# plutôt que vers le RDV collectif.
# Ce concern implémente ce comportement en stockant dans Redis l’URL referer de la
# recherche de créneaux.
# On ne stocke pas dans la session pour éviter des cookies overflow.
# On stocke une valeur pour chaque formulaire pour permettre des onglets parallèles.

module Admin::RdvsCollectifs::ReturnToControllerConcern
  extend ActiveSupport::Concern

  # rubocop:disable Rails/LexicallyScopedActionFilter
  included do
    before_action :store_return_to, only: :edit
    before_action :fetch_return_to, only: :update
  end
  # rubocop:enable Rails/LexicallyScopedActionFilter

  private

  def redis_key
    "rdv_collectif_return_to_after_add_participant:#{current_agent.id}:#{@return_to_form_id}"
  end

  def store_return_to
    return unless referer_is_creneaux_search_with_user?(request.referer)

    @return_to_form_id = SecureRandom.hex(8)
    Redis.with_connection { _1.setex(redis_key, 1.hour.to_i, request.referer) }
  rescue Redis::BaseError, ConnectionPool::TimeoutError => e
    Sentry.capture_exception(e)
  end

  def fetch_return_to
    @return_to_form_id = params[:return_to_form_id]
    @return_to = @return_to_form_id && Redis.with_connection { _1.get(redis_key) }
  rescue Redis::BaseError, ConnectionPool::TimeoutError => e
    Sentry.capture_exception(e)
  end

  def referer_is_creneaux_search_with_user?(url)
    return false if url.blank?

    uri = URI.parse(url)
    return false unless uri.path == admin_organisation_creneaux_search_selection_creneaux_path(current_organisation)

    Rack::Utils.parse_nested_query(uri.query)["user_ids"].present?
  rescue URI::InvalidURIError
    false
  end
end
