#
# Cette API est appelée par la cartographie du déploiement de la suite territoriale.
# Voir docs/interconnexions/carto_anct.md
#
class Api::Anct::MetricsController < ActionController::Base # rubocop:disable Rails/ApplicationController
  before_action :authorize_via_shared_secret

  def index
    all_metrics = CartoAnct.cached_metrics

    paginated_results = all_metrics.drop(params[:offset].presence.to_i || 0)
    paginated_results = paginated_results.take(params[:limit].to_i) if params[:limit].present?

    output = {
      count: all_metrics.size,
      results: paginated_results,
    }

    render json: output
  end

  private

  def authorize_via_shared_secret
    if ENV["CARTO_ANCT_SHARED_SECRET"].blank? || headers["Authorization"] != "Bearer #{ENV["CARTO_ANCT_SHARED_SECRET"]}"
      head :unauthorized
    end
  end
end
