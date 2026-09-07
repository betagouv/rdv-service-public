class SearchController < ApplicationController
  layout "application_base"

  include RestrictedAuthConcern
  include Search::LogParamsConcern

  # Peut être utilisé soit pour une invitation de RDV insertion ou pour une invitation à reprendre rendez-vous suite à une annulation
  prepend_before_action only: %i[search_rdv] do
    store_restricted_auth_token_in_session_and_redirect(allow_rdv_insertion_invitation: true)
  end

  def home
    # Si l'agent est redirigé vers le root_path depuis ProConnect, et qu'on veut le rediriger vers
    # une application OAuth cliente (par exemple RDV Insertion)
    # après la déconnexion, on suit l'url de redirection
    post_logout_redirect_url = session.delete(:post_logout_redirect_url)

    if post_logout_redirect_url
      redirect_to post_logout_redirect_url, allow_other_host: true
      return
    end

    if current_domain == Domain::RDV_SERVICE_PUBLIC
      @site_vitrine_page = true
      render "static_pages/homepage_anct"
    elsif current_domain == Domain::RDV_SERVICE_PUBLIC_ETAT
      @site_vitrine_page = true
      render "static_pages/homepage_etat"
    else
      search_rdv
    end
  end

  def search_rdv
    if search_on_migrated_organisation
      redirect_to migrated_organisation_booking_url, allow_other_host: true
    elsif current_agent && params[:prescripteur] == Prescripteur::INTERNE && params[:current_organisation]
      redirect_to search_creneau_admin_organisation_prescription_path(params[:current_organisation], agent_search_params)
    else
      @context = if rdv_insertion_invitation_query_params.present?
                   WebInvitationSearchContext.new(user: current_user, query_params: search_params.merge(rdv_insertion_invitation_query_params))
                 else
                   WebSearchContext.new(user: current_user, query_params: search_params)
                 end

      @current_step = CreneauWizardForUsers::CurrentStepPicker.new(@context).current_step

      if search_allowed?
        render :search_rdv
      else
        redirect_to root_path
      end
    end
  end

  # Les organisations créées avant cette date restent accessibles via /org/:id
  LEGACY_INCREMENTAL_ID_CUTOFF_DATE = Date.new(2026, 1, 20).freeze

  def public_link_with_internal_organisation_id
    organisation =
      Organisation.find_by(public_link_id: params[:organisation_id]) ||
      Organisation.where("created_at < ?", LEGACY_INCREMENTAL_ID_CUTOFF_DATE).find_by(id: params[:organisation_id])

    raise ActiveRecord::RecordNotFound if organisation.nil?

    redirect_to_organisation_search(organisation)
  end

  def public_link_with_public_motif_id
    motif = Motif.find_by(public_link_id: params[:public_link_id])
    if motif
      redirect_to_organisation_search(motif.organisation, **{ motif:, prescripteur: params[:prescripteur] }.compact)
    else
      redirect_to root_path, flash: { error: "Motif introuvable" }
    end
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
    redirect_to prendre_rdv_path(request.query_parameters.merge(prescripteur: 1))
  end

  private

  # Les clés du hash renvoyé par cette méthode devraient correspondre à InvitationSearchContext::INVITATION_PARAMS
  def rdv_insertion_invitation_query_params
    session[:rdv_insertion_invitation]&.symbolize_keys
  end

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

  def redirect_to_organisation_search(organisation, motif: nil, prescripteur: nil)
    if organisation
      redirect_to prendre_rdv_path({
        public_link_organisation_id: organisation.id,
        departement: organisation.territory.departement_number,
        motif_id: motif&.id,
        prescripteur:,
      }.compact)
    else
      flash[:alert] = "Organisation non trouvée"
      redirect_to root_path
    end
  end

  def search_allowed?
    current_domain.provides_address_selection? || # toujours autorisé sur RDVS
      (@current_step != :address_selection && params[:public_link_organisation_id].present?) || # toujours scopé sur RDVSP
      exception_for_cdad_21?
  end

  def exception_for_cdad_21?
    # dans le le CDAD de la Côte d'Or,  les agents ont distribué un lien de prise de rendez-vous à
    # l'échelle de leur espace. Pour éviter de casser ce lien, et en attendant d'avoir une solution plus pérenne,
    # on autorise l'utilisation du paramètre departement dans ce cas.
    # Leur nom de département étant C21, il n'y a pas de risque de permettre de scraper d'autres territoires.
    params[:departement] == "C21"
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
end
