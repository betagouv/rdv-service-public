class CreneauWizardForUsers::Steps::CreneauSelection
  def initialize(search_context)
    @context = search_context
  end

  def no_availability?
    creneaux.empty? && next_availability.nil?
  end

  def next_availability
    @next_availability ||= creneaux.empty? ? creneaux_search.next_availability : nil
  end

  delegate :creneaux, to: :creneaux_search

  def after_max_public_booking_delay?(date)
    date >= (Time.zone.now + @context.first_matching_motif.max_public_booking_delay.seconds).to_date
  end

  def available_collective_rdvs
    @available_collective_rdvs ||= creneaux_search.available_collective_rdvs
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

  private

  def creneaux_search
    @creneaux_search ||= @context.creneaux_search_for(@context.lieu, @context.first_matching_motif)
  end
end
