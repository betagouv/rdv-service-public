class JusticeLieuxMatch < ApplicationRecord
  belongs_to :lieu

  def reservation_en_ligne
    lieu.plage_ouvertures.joins(:motifs).where(
      motifs: { bookable_by: :everyone },
      plage_ouvertures: { expired_cached: false }
    ).any?
  end

  def url(request)
    Rails.application.routes.url_helpers.public_link_to_org_url(
      organisation_id: lieu.organisation_id,
      org_slug: lieu.organisation.slug,
      host: URI.parse(request.url).host
    )
  end
end
