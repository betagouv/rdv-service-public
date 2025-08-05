class CreneauWizardForUsers::Steps::CreneauSelection
  def initialize(web_search_context)
    @context = web_search_context
    @starting_conditions = @context.starting_conditions
  end

  def no_availability?
    creneaux.empty? && @context.next_availability.nil?
  end

  delegate :creneaux, to: :creneaux_search

  def wizard_after_creneau_selection_path(params)
    url_helpers = Rails.application.routes.url_helpers
    if @starting_conditions.prescription_interne?
      organisation = @starting_conditions.current_organisation
      if @context.user
        url_helpers.recapitulatif_admin_organisation_prescription_path(organisation, params.merge(@context.query_params))
      else
        url_helpers.user_selection_admin_organisation_prescription_path(organisation, params.merge(@context.query_params))
      end

    elsif @starting_conditions.prescripteur?

      url_helpers.prescripteur_start_path(@context.query_params.merge(params))
    else
      url_helpers.new_users_rdv_wizard_step_path(@context.query_params.merge(params))
    end
  end

  private

  def creneaux_search
    @context.creneaux_search
  end
end
