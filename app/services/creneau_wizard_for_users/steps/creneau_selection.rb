class CreneauWizardForUsers::Steps::CreneauSelection
  def initialize(search_context)
    @context = search_context
    @creneaux_search = @context.creneaux_search
  end

  def no_availability?
    creneaux.empty? && next_availability.nil?
  end

  def next_availability
    @next_availability ||= creneaux.empty? ? @creneaux_search.next_availability : nil
  end

  delegate :creneaux, to: :@creneaux_search

  def after_max_public_booking_delay?(date)
    # On a déjà le first_matching_motif en mémoire au moment où on appelle cette méthode
    # Dans la plupart des cas, tous les motifs ont le même max_booking_delay
    # On s'en sert donc pour éviter de chercher le maximum sur tous les matching_motifs si possible
    if date < (Time.zone.now + @context.first_matching_motif.max_public_booking_delay.seconds).to_date
      return false
    end

    # TODO: on pourrait peut-être rendre cette requête plus rapide avec un index sur motifs.max_public_booking_delay
    # Elle peut etre assez longue, donc on fait un memoize pour éviter de la faire plusieurs fois
    @max_public_booking_delay ||= @context.matching_motifs.maximum("max_public_booking_delay")

    date >= (Time.zone.now + @max_public_booking_delay.seconds).to_date
  end

  def wizard_after_creneau_selection_path(params)
    url_helpers = Rails.application.routes.url_helpers

    if @context.query_params[:prescripteur] == Prescripteur::INTERNE
      # context est un AgentPrescriptionSearchContext
      organisation = @context.current_organisation
      if @context.user
        url_helpers.recapitulatif_admin_organisation_prescription_path(organisation, params.merge(@context.query_params))
      else
        url_helpers.user_selection_admin_organisation_prescription_path(organisation, params.merge(@context.query_params))
      end

    elsif @context.prescripteur?

      url_helpers.prescripteur_start_path(@context.query_params.merge(params))
    else
      url_helpers.new_users_rdv_wizard_step_path(@context.query_params.merge(params))
    end
  end
end
