# frozen_string_literal: true

#
# Cette API a été introduite dans une démarche exploratoire décrit ici :
# https://github.com/betagouv/rdv-solidarites.fr/issues/2874
#
# Ce code n'est pas sacré, au contraire, il a été conçu pour être jetable.
# Il pourra donc :
# - soit être jeté parce qu'il n'est plus utilisé
# - soit être adapté / déplacé dans une API plus propre si
#   le besoin auquel il répond se généralise.
#
# Les utilisateurs de cette API sont :
# - l'équipe carto CNFS,
# - l'équipe carto ANCT,
# - Rés'In (métropole de Lyon)
#
class PublicApi::V1::PublicLinksController < PublicApi::V1::BaseController
  before_action -> { check_parameters_presence(:territory) }
  before_action :set_territory

  def index
    # Using cache to prevent overloading db in case of accidentally intensive API calls
    response_body = Rails.cache.fetch("public_api/v1/public_links/#{@territory.id}", expires_in: 1.minute) do
      { public_links: public_links_for(@territory) }.to_json
    end

    render json: response_body
  end

  private

  def public_links_for(territory)
    plage_ouvertures_scope = PlageOuverture
      .not_expired
      .in_range((Time.zone.now..))
      .reservable_online

    organisations = Organisation
      .where(territory: territory)
      .where.not(external_id: nil)
      .joins(:plage_ouvertures)
      .merge(plage_ouvertures_scope)
      .distinct

    organisations.map do |organisation|
      {
        external_id: organisation.external_id,
        public_link: public_link_to_org_url(organisation_id: organisation, host: organisation.domain.dns_domain_name),
      }
    end
  end

  def set_territory
    @territory = Territory.find_by(departement_number: params[:territory])
    render_error :not_found, not_found: :territory unless @territory
  end
end
