class Api::Justice::LieuxController < ActionController::Base
  def index
    render json: {
      lieux:
      JusticeLieuxMatch.all.map do |match|
        {
          ee_id: match.ee_id,
          reservation_en_ligne: match.lieu.plage_ouvertures.joins(:motifs).where(motifs: { bookable_by: :everyone }).where(plage_ouvertures: { expired_cached: false }).any?,
          url: Rails.application.routes.url_helpers.public_link_to_org_url(organisation_id: match.lieu.organisation_id, org_slug: match.lieu.organisation.slug, host: URI.parse(request.url).host),
        }
      end,
    }
  end
end
