# frozen_string_literal: true

class Api::V1::OrganisationsController < Api::V1::BaseController
  def index
    organisations = policy_scope(Organisation)
    organisations = organisations.where(id: organisations_relevant_to_sector.pluck(:id)) if geo_params?
    render_collection(organisations.order(:id))
  end

  private

  def organisations_relevant_to_sector
    Users::GeoSearch.new(
      departement: params[:departement_number],
      city_code: params[:city_code],
      street_ban_id: params[:street_ban_id],
    ).most_relevant_organisations
  end

  def geo_params?
    [params[:city_code], params[:street_ban_id]].any?(&:present?)
  end
end
