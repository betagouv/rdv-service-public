class Users::RdvWizardStepsController < UserAuthController
  layout "application_base"

  RDV_PERMITTED_PARAMS = [:starts_at, :motif_id, :context, { user_ids: [] }].freeze
  EXTRA_PERMITTED_PARAMS = [
    *WebSearchContext::ADDRESS_SELECTION_PARAMS,
    :lieu_id, :where, :created_user_id, :rdv_collectif_id, :user_selected_organisation_id,
    :public_link_organisation_id, :duration, :ants_pre_demandes_count,
    { organisation_ids: [], referent_ids: [], external_organisation_ids: [] },
  ].freeze

  include TokenInvitable

  def new
    @rdv_wizard = rdv_wizard_for(current_user, query_params)
    @rdv = @rdv_wizard.rdv
    authorize(@rdv, policy_class: User::RdvPolicy)
    if @rdv_wizard.creneau.present?
      render current_step[:name], locals: { current_step:, max_step: steps.size, next_step: }
    else
      flash[:error] = "Ce créneau n'est plus disponible. Veuillez en sélectionner un autre."
      redirect_to(prendre_rdv_path(@rdv_wizard.to_query))
    end
  end

  def create
    @rdv_wizard = rdv_wizard_for(current_user, rdv_params.merge(user_params))
    @rdv = @rdv_wizard.rdv
    skip_authorization
    if @rdv_wizard.valid? && @rdv_wizard.user.benign_errors.blank? && @rdv_wizard.save
      redirect_to new_users_rdv_wizard_step_path(@rdv_wizard.to_query.merge(step: next_step[:number]))
    else
      render current_step[:name], locals: { current_step:, max_step: steps.size, next_step: }
    end
  end

  protected

  def steps
    steps = {
      step1: {
        name: "step1",
        number: 1,
        title: "Vos informations",
        next_step: current_user.signed_in_with_invitation_token? ? :step3 : :step2,
        stepper_index: 1,
      },
      step2: {
        name: "step2",
        number: 2,
        title: "Choix de l’usager",
        stepper_index: 2,
      },
    }

    # Dans le cas d'une invitation, on passe l’étape 2
    steps.delete(:step2) if current_user.signed_in_with_invitation_token?

    steps
  end

  def current_step
    return steps[:step1] if params[:step].blank?

    step = "step#{params[:step]}"
    raise "Invalid step: #{step.inspect}" unless steps.key?(step.to_sym)

    steps[step.to_sym]
  end

  def next_step
    steps[current_step[:next_step]]
  end

  def rdv_wizard_for(current_user, request_params)
    klass = "UserRdvWizard::#{current_step[:name].camelize}".constantize
    klass.new(current_user, request_params)
  end

  def rdv_params
    params.require(:rdv).permit(*RDV_PERMITTED_PARAMS).merge(params.permit(*EXTRA_PERMITTED_PARAMS))
  end

  def query_params
    params.permit(*RDV_PERMITTED_PARAMS, *EXTRA_PERMITTED_PARAMS)
  end

  def user_params
    params.permit(user: [
                    :first_name,
                    :last_name,
                    :birth_name,
                    :phone_number,
                    :birth_date,
                    :email,
                    :notification_email,
                    :address,
                    :caisse_affiliation,
                    :affiliation_number,
                    :family_situation,
                    :number_of_children,
                    :notify_by_email,
                    :notify_by_sms,
                    :ants_pre_demande_number,
                    :ignore_benign_errors,
                    { user_profiles_attributes: %i[logement id organisation_id] },
                  ])
  end
end
