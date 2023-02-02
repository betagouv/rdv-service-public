# frozen_string_literal: true

class SearchController < ApplicationController
  include TokenInvitable

  # utilisé par le Pas-de-Calais pour prendre rdv depuis leur site : https://www.pasdecalais.fr/Solidarite-Sante/Enfance-et-famille/La-Protection-Maternelle-et-Infantile/Prendre-rendez-vous-en-ligne-en-MDS-PMI-ou-service-social
  after_action :allow_iframe

  def search_rdv
    @context = SearchContext.new(current_user, search_params.to_h)
  end

  def public_link_with_internal_organisation_id
    organisation = Organisation.find(params[:organisation_id])
    redirect_to_organisation_search(organisation)
  end

  def public_link_with_external_organisation_id
    territory = Territory.find_by!(departement_number: params[:territory])
    organisation = territory.organisations.find_by!(external_id: params[:organisation_external_id])
    redirect_to_organisation_search(organisation)
  end

  def resin
    redirect_to prendre_rdv_path(
      departement: "CN",
      service_id: Service.find_by(name: Service::CONSEILLER_NUMERIQUE)&.id,
      motif_name_with_location_type: "Accompagnement individuel-public_office",
      external_organisation_ids: params[:external_organisation_ids].split(",")
    )
  end

  private

  def redirect_to_organisation_search(organisation)
    if organisation
      redirect_to prendre_rdv_path(
        public_link_organisation_id: organisation.id, departement: organisation.territory.departement_number
      )
    else
      flash[:alert] = "Organisation non trouvée"
      redirect_to root_path
    end
  end

  def search_params
    params.permit(
      :latitude, :longitude, :address, :city_code, :departement, :street_ban_id,
      :service_id, :lieu_id, :date, :motif_search_terms, :motif_name_with_location_type, :motif_category,
      :invitation_token, :motif_id, :public_link_organisation_id, :user_selected_organisation_id,
      organisation_ids: [], referent_ids: [], external_organisation_ids: []
    )
  end
end
