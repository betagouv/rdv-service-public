# frozen_string_literal: true

class PublicApi::PublicLinksController < ActionController::Base # rubocop:disable Rails/ApplicationController
  def index
    departement_number = params.require(:territory).presence

    territory = Territory.find_by!(departement_number: departement_number)

    # Using cache to prevent overloading db in case of accidentally intensive API calls
    response_body = Rails.cache.fetch("public_api/public_links/#{territory.id}", expires_in: 1.minute) do
      { public_links: public_links_for(territory) }.to_json
    end

    render json: response_body
  end

  private

  def public_links_for(territory)
    plage_ouvertures_scope = PlageOuverture
      .not_expired
      .in_range((Time.zone.now..))
      .reservable_online

    organisations = Organisation.where(territory: territory).joins(:plage_ouvertures).merge(plage_ouvertures_scope).distinct

    organisations.map do |organisation|
      {
        external_id: organisation.external_id,
        public_link: public_link_to_org_url(organisation_id: organisation.id, host: organisation.domain.dns_domain_name),
      }
    end
  end
end
