class SearchController < ApplicationController
  layout "application_base"

  include TokenInvitable
  prepend_before_action :store_invitation_in_session_and_redirect, only: %i[search_rdv]

  def home
    # Si l'agent est redirigé vers le root_path depuis ProConnect, et qu'on veut le rediriger vers
    # une application OAuth cliente (par exemple RDV Insertion)
    # après la déconnexion, on suit l'url de redirection
    post_logout_redirect_url = session.delete(:post_logout_redirect_url)

    if post_logout_redirect_url
      redirect_to post_logout_redirect_url, allow_other_host: true
      return
    end

    # << REMOVE AFTER 01/01/2026
    # Bien que nous n’utilisions plus Crisp pour les nouveaux tickets, nous avons encore quelques tickets ouverts
    # On laisse cette redirection pour les personnes qui cliquent sur « Répondre via le chat »
    #
    # Crisp propose aux utilisateurs de répondre aux mails soit par réponse de mail soit par le chat
    # Comme nous ne pouvons pas retirer la mention du chat et que nous ne souhaitons pas le proposer comme moyen de
    # contact, nous redirigeons les utilisateurs vers le chat Crisp si ils cliquent sur le lien dans le footer du mail
    if params[:crisp_sid]
      redirect_to_crisp_chat(params[:crisp_sid])
      return
    end
    # >> REMOVE AFTER 01/01/2026

    if current_domain == Domain::RDV_SERVICE_PUBLIC
      @site_vitrine_page = true
      render "dsfr/rdv_mairie/homepage"
    else
      search_rdv
    end
  end

  def search_rdv # rubocop:disable Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity
    if search_on_migrated_organisation
      redirect_to migrated_organisation_booking_url, allow_other_host: true
    elsif current_agent && params[:prescripteur] == Prescripteur::INTERNE && params[:current_organisation]
      redirect_to search_creneau_admin_organisation_prescription_path(params[:current_organisation], agent_search_params)
    else
      @context = if invitation&.to_take_rdv?
                   WebInvitationSearchContext.new(user: current_user, query_params: search_params.merge(invitation.query_params))
                 else
                   WebSearchContext.new(user: current_user, query_params: search_params)
                 end

      @current_step = CreneauWizardForUsers::CurrentStepPicker.new(@context).current_step

      if !current_domain.provides_address_selection? && @current_step == :address_selection
        redirect_to root_path
      else
        render :search_rdv
      end
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
      duration: params[:duration], # TODO: supprimer ce param
      ants_pre_demandes_count: params[:ants_pre_demandes_count]
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

  def search_on_migrated_organisation
    return false unless current_domain == Domain::RDV_AIDE_NUMERIQUE && params[:public_link_organisation_id]

    organisation = Organisation.find(params[:public_link_organisation_id])

    return false if organisation.motifs.active.any?

    InstanceExport.finished_exports_for_organisation(organisation.id).any?
  end

  def migrated_organisation_booking_url
    organisation = Organisation.find(params[:public_link_organisation_id])

    export = InstanceExport.finished_exports_for_organisation(organisation.id).first

    public_link_to_org_url(organisation_id: export.destination_organisation_id, org_slug: organisation.slug, host: ENV["RDV_SERVICE_PUBLIC_OAUTH_BASE_URL"])
  end

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
      :motif_category_short_name, :date, :public_link_organisation_id, :prescripteur, :autofocus,
      organisation_ids: [], referent_ids: [], external_organisation_ids: []
    ).to_h.deep_symbolize_keys
  end

  def agent_search_params
    params.permit(AgentPrescriptionSearchContext::STRONG_PARAMS_LIST)
  end

  # << REMOVE AFTER 01/01/2026
  def redirect_to_crisp_chat(crisp_sid)
    redirect_to "https://go.crisp.chat/chat/embed/?website_id=#{ENV['CRISP_WEBSITE_ID']}&crisp_sid=#{crisp_sid}", allow_other_host: true
  end
  # >> REMOVE AFTER 01/01/2026
end
