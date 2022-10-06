# frozen_string_literal: true

class PublicApi::PublicLinksController < ActionController::Base # rubocop:disable Rails/ApplicationController
  def index
    departement = params.require(:departement).presence

    territory = Territory.find_by!(departement_number: departement)

    plage_ouvertures = PlageOuverture.where(organisations: { territory_id: territory.id })
      .not_expired
      .in_range((Time.zone.now..))
      .reservable_online
      .joins(:organisation)
      .distinct(:organisation_id)

    results = plage_ouvertures.map do |plage_ouverture|
      {
        external_id: plage_ouverture.organisation.external_id,
        public_link: public_link_to_org_url(organisation_id: plage_ouverture.organisation.id, host: plage_ouverture.organisation.domain.dns_domain_name),
      }
    end

    render json: { public_links: results }.to_json
  end
end
