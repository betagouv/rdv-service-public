# frozen_string_literal: true

class PublicApi::PublicLinksController < ActionController::Base # rubocop:disable Rails/ApplicationController
  def index
    departement = params.require(:departement).presence

    territory = Territory.find_by!(departement_number: departement)

    # Using cache to prevent overloading db in case of accidentally intensive API calls
    response_body = Rails.cache.fetch("public_api/public_links/#{territory.id}", expires_in: 1.minute) do
      { public_links: public_links_for(territory) }.to_json
    end

    render json: response_body
  end

  private

  def public_links_for(territory)
    plage_ouvertures = PlageOuverture.where(organisations: { territory_id: territory.id })
      .not_expired
      .in_range((Time.zone.now..))
      .reservable_online
      .joins(:organisation)
      .distinct(:organisation_id)

    plage_ouvertures.map do |plage_ouverture|
      {
        external_id: plage_ouverture.organisation.external_id,
        public_link: public_link_to_org_url(organisation_id: plage_ouverture.organisation.id, host: plage_ouverture.organisation.domain.dns_domain_name),
      }
    end
  end
end
