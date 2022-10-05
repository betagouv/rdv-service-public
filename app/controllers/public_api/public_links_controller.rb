# frozen_string_literal: true

class PublicApi::PublicLinksController < ActionController::Base # rubocop:disable Rails/ApplicationController
  def index
    departement = params.require(:departement).presence
    org_ext_ids = params.require(:external_ids).compact_blank

    territory = Territory.find_by!(departement_number: departement)

    plage_ouvertures = PlageOuverture.where(organisations: { external_id: org_ext_ids, territory_id: territory.id })
      .not_expired
      .in_range((Time.zone.now..))
      .reservable_online
      .joins(:organisation)
      .distinct(:organisation_id)

    results = plage_ouvertures.to_h do |plage_ouverture|
      [
        plage_ouverture.organisation.external_id,
        public_link_to_org_url(organisation_id: plage_ouverture.organisation.id, host: plage_ouverture.organisation.domain.dns_domain_name),
      ]
    end

    render json: results.to_json
  end
end
