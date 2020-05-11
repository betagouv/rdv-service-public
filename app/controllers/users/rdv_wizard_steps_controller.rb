class Users::RdvWizardStepsController < UserAuthController

  def new
    @rdv_wizard = rdv_wizard_for(current_user, rdv_params.merge(**new_rdv_extra_params))
    @rdv = @rdv_wizard.rdv
    authorize(@rdv)
    if @rdv_wizard.creneau.available?
      render current_step
    else
      flash[:error] = "Ce créneau n'est plus disponible. Veuillez en sélectionner un autre."
      redirect_to lieux_path(search: @rdv_wizard.to_query)
    end
  end

  def create
    @rdv_wizard = rdv_wizard_for(current_user, rdv_params.merge(**new_rdv_extra_params))
    @rdv = @rdv_wizard.rdv
    skip_authorization
    if @rdv_wizard.valid?
      redirect_to new_users_rdv_wizard_step_path(@rdv_wizard.to_query.merge(step: next_step_index))
    else
      render current_step
    end
  end

  protected

  def current_step
    return UserRdvWizard::STEPS.first if params[:step].blank?

    step = "step#{params[:step]}"
    raise InvalidStep unless step.in?(UserRdvWizard::STEPS)

    step
  end

  def next_step_index
    UserRdvWizard::STEPS.index(current_step) + 2 # steps start at 1 + increment
  end

  def rdv_wizard_for(current_user, request_params)
    klass = "UserRdvWizard::#{current_step.camelize}".constantize
    klass.new(current_user, request_params)
  end

  def new_rdv_extra_params
    params.permit(:lieu_id, :motif_name, :departement, :where, :created_user_id)
  end

  def rdv_params
    params.require(:rdv).permit(:starts_at, :motif_id, user_ids: [])
  end
end
