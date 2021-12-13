# frozen_string_literal: true

class Api::V1::OrganisationsController < Api::V1::BaseController
  def index
    organisations = policy_scope(Organisation)
    organisations = organisations.merge(organisations_attributed_to_sector) if geo_params?
    render_collection(organisations.order(:id))
  end

  private

  def organisations_attributed_to_sector
    Users::GeoSearch.new(
      departement: params[:departement_number],
      city_code: params[:city_code],
      street_ban_id: params[:street_ban_id]
    ).attributed_organisations
  end

  def geo_params?
    [params[:city_code], params[:street_ban_id]].any?(&:present?)
  end
end
