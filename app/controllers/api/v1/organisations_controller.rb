# frozen_string_literal: true

class Api::V1::OrganisationsController < Api::V1::AgentAuthBaseController
  before_action :set_organisation, only: %i[show update]

  def index
    organisations = policy_scope(Organisation)
    organisations = organisations.where(id: organisations_relevant_to_sector.pluck(:id)) if geo_params?
    render_collection(organisations.order(:id))
  end

  def show
    render_record @organisation
  end

  def update
    @organisation.update!(organisation_params)
    render_record @organisation
  end

  private

  def set_organisation
    @organisation = Organisation.find(params[:id])
    authorize @organisation
  end

  def organisation_params
    params.permit(:name, :phone_number, :email)
  end

  def organisations_relevant_to_sector
    Users::GeoSearch.new(
      departement: params[:departement_number],
      city_code: params[:city_code],
      street_ban_id: params[:street_ban_id]
    ).most_relevant_organisations
  end

  def geo_params?
    [params[:city_code], params[:street_ban_id]].any?(&:present?)
  end
end
