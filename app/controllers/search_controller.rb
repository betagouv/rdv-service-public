class SearchController < ApplicationController
  layout "application_base"

  include TokenInvitable

  # utilisé par le Pas-de-Calais pour prendre rdv depuis leur site : https://www.pasdecalais.fr/Solidarite-Sante/Enfance-et-famille/La-Protection-Maternelle-et-Infantile/Prendre-rendez-vous-en-ligne-en-MDS-PMI-ou-service-social
  after_action :allow_iframe

  def search_rdv
    # TODO : public_link_organisation_id has to work if agent is logged in ?
    if current_agent && params[:prescripteur] == Prescripteur::INTERNE && session[:agent_prescripteur_organisation_id]
      redirect_to search_creneau_admin_organisation_prescription_path(session[:agent_prescripteur_organisation_id], agent_search_params)
    end
    @context = if invitation?
                 WebInvitationSearchContext.new(user: current_user, query_params: query_params)
               else
                 WebSearchContext.new(user: current_user, query_params: query_params)
               end
    if current_domain == Domain::RDV_MAIRIE && request.path == "/"
      render "dsfr/rdv_mairie/homepage", layout: "application_dsfr"
    end
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

  def public_link_to_creneaux
    motif = Motif.find(params[:motif_id])

    redirect_to new_users_rdv_wizard_step_path(
      starts_at: params[:starts_at],
      lieu_id: params[:lieu_id],
      departement: motif.organisation.departement_number,
      motif_name_with_location_type: motif.name_with_location_type,
      motif_id: motif.id,
      public_link_organisation_id: params[:public_link_organisation_id],
      duration: params[:duration]
    )
  end

  def resin
    redirect_to prendre_rdv_path(
      departement: Territory::CN_DEPARTEMENT_NUMBER,
      service_id: Service.find_by(name: Service::CONSEILLER_NUMERIQUE)&.id,
      motif_name_with_location_type: "accompagnement_individuel-public_office",
      external_organisation_ids: params[:external_organisation_ids].split(","),
      prescripteur: 1
    )
  end

  def prescripteur
    redirect_to prendre_rdv_path(
      prescripteur: 1
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

  def query_params
    search_params.to_h.deep_symbolize_keys.merge(invitation? ? invitation.query_params : {})
  end

  def invitation?
    invitation.present? && invitation.to_take_rdv?
  end

  def search_params
    params.permit(
      :latitude, :longitude, :address, :city_code, :departement, :street_ban_id,
      :service_id, :lieu_id, :date, :motif_name_with_location_type, :motif_category_short_name,
      :motif_id, :public_link_organisation_id, :user_selected_organisation_id, :prescripteur,
      organisation_ids: [], referent_ids: [], external_organisation_ids: []
    )
  end

  def agent_search_params
    params.permit(AgentPrescriptionSearchContext::STRONG_PARAMS_LIST)
  end
end
