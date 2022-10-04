# frozen_string_literal: true

class PublicApi::PublicLinksController < ActionController::Base
  def index
    departement = params.require(:departement).presence
    org_ext_ids = params.require(:external_ids).compact_blank

    territory = Territory.find_by!(departement_number: departement)
    organisations = territory.organisations.where(external_id: org_ext_ids)

    organisations
      .joins("LEFT OUTER JOIN plage_ouvertures")


    results = organisations.map do |organisation|
      plages = PlageOuverture
        .where(organisation: organisation)
        .not_expired
        .in_range((Time.zone.now..))
        .reservable_online

      {
        organisation_external_id: organisation.external_id,
        reservation_disponible: plages.any?,
        public_url: public_link_to_org_url(organisation_id: organisation.id, host: organisation.domain.dns_domain_name),
      }
    end

    render json: results.to_json
  end
end
