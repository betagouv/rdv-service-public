class SearchController < ApplicationController
  layout "application_base"

  include TokenInvitable
  prepend_before_action :store_invitation_in_session_and_redirect, only: %i[search_rdv]

  # utilisé par le Pas-de-Calais pour prendre rdv depuis leur site : https://www.pasdecalais.fr/Solidarite-Sante/Enfance-et-famille/La-Protection-Maternelle-et-Infantile/Prendre-rendez-vous-en-ligne-en-MDS-PMI-ou-service-social
  after_action :allow_iframe

  def home
    # Si l'agent est redirigé vers le root_path depuis ProConnect, et qu'on veut le rediriger vers
    # une application OAuth cliente (par exemple RDV Insertion)
    # après la déconnexion, on suit l'url de redirection
    post_logout_redirect_url = session.delete(:post_logout_redirect_url)

    if post_logout_redirect_url
      redirect_to post_logout_redirect_url, allow_other_host: true
      return
    end

    # Crisp propose aux utilisateurs de répondre aux mails soit par réponse de mail soit par le chat
    # Comme nous ne pouvons pas retirer la mention du chat et que nous ne souhaitons pas le proposer comme moyen de
    # contact, nous redirigeons les utilisateurs vers le chat Crisp si ils cliquent sur le lien dans le footer du mail
    if params[:crisp_sid]
      redirect_to_crisp_chat(params[:crisp_sid])
      return
    end

    if current_domain == Domain::RDV_MAIRIE
      render "dsfr/rdv_mairie/homepage"
    else
      search_rdv
    end
  end

  # rubocop:disable Metrics/PerceivedComplexity
  def search_rdv
    # TODO : public_link_organisation_id has to work if agent is logged in ?
    if current_agent && params[:prescripteur] == Prescripteur::INTERNE && session[:agent_prescripteur_organisation_id]
      redirect_to search_creneau_admin_organisation_prescription_path(session[:agent_prescripteur_organisation_id], agent_search_params)
    else
      @context = if invitation&.to_take_rdv?
                   WebInvitationSearchContext.new(user: current_user, query_params: search_params.merge(invitation.query_params))
                 else
                   WebSearchContext.new(user: current_user, query_params: search_params)
                 end

      if !current_domain.provides_address_selection? && @context.current_step == :address_selection
        redirect_to root_path
      else
        render :search_rdv
      end
    end
  end
  # rubocop:enable Metrics/PerceivedComplexity

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
    redirect_to prendre_rdv_path(prescripteur: 1)
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
      *WebSearchContext::ADDRESS_SELECTION_PARAMS,
      *WebSearchContext::USER_CHOICE_PARAMS,
      :motif_category_short_name, :date, :public_link_organisation_id, :prescripteur,
      organisation_ids: [], referent_ids: [], external_organisation_ids: []
    ).to_h.deep_symbolize_keys
  end

  def agent_search_params
    params.permit(AgentPrescriptionSearchContext::STRONG_PARAMS_LIST)
  end

  def redirect_to_crisp_chat(crisp_sid)
    redirect_to "https://go.crisp.chat/chat/embed/?website_id=#{ENV['CRISP_WEBSITE_ID']}&crisp_sid=#{crisp_sid}", allow_other_host: true
  end
end
