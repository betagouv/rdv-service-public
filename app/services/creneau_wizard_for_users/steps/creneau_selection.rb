class CreneauWizardForUsers::Steps::CreneauSelection
  def initialize(search_context)
    @context = search_context
    @query_params = @context.query_params

    @start_date = @context.start_date
    @motif = @context.first_matching_motif
    @creneaux_search = @context.creneaux_search_for(@context.lieu, @motif)
  end

  def date_range
    @start_date..(@start_date + 6.days)
  end

  def no_availability?
    creneaux.empty? && next_availability.nil?
  end

  def next_availability
    @next_availability ||= creneaux.empty? ? @creneaux_search.next_availability : nil
  end

  delegate :creneaux, to: :@creneaux_search

  def after_max_public_booking_delay?(date)
    date >= (Time.zone.now + @motif.max_public_booking_delay.seconds).to_date
  end

  def available_collective_rdvs
    @available_collective_rdvs ||= @creneaux_search.available_collective_rdvs
  end

  def previous_week_path
    previous_from_date = date_range.begin - 7.days
    current_step_path(date: previous_from_date, autofocus: "last")
  end

  def next_week_path
    current_step_path(date: date_range.end + 1.day, autofocus: "first")
  end

  def next_availability_path
    current_step_path(date: next_availability.starts_at, autofocus: "first")
  end

  def wizard_after_creneau_selection_path(params)
    if @context.query_params[:prescripteur] == Prescripteur::INTERNE
      # context est un AgentPrescriptionSearchContext
      organisation = @context.current_organisation
      if @context.user
        url_helpers.recapitulatif_admin_organisation_prescription_path(organisation, params.merge(@query_params))
      else
        url_helpers.user_selection_admin_organisation_prescription_path(organisation, params.merge(@query_params))
      end

    elsif @context.prescripteur?

      url_helpers.prescripteur_start_path(@query_params.merge(params))
    else
      url_helpers.new_users_rdv_wizard_step_path(@query_params.merge(params))
    end
  end

  private

  def current_step_path(extra_params)
    url_helpers.prendre_rdv_path(@query_params.merge(extra_params))
  end

  def url_helpers
    Rails.application.routes.url_helpers
  end
end
