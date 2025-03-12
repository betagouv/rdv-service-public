class Users::RdvWizardStepsController < UserAuthController
  RDV_PERMITTED_PARAMS = [:starts_at, :motif_id, :context, { user_ids: [] }].freeze
  EXTRA_PERMITTED_PARAMS = [
    *WebSearchContext::ADDRESS_SELECTION_PARAMS,
    :lieu_id, :where, :created_user_id, :rdv_collectif_id, :user_selected_organisation_id,
    :public_link_organisation_id, :duration,
    { organisation_ids: [], referent_ids: [], external_organisation_ids: [] },
  ].freeze
  after_action :allow_iframe
  before_action :set_current_step_index
  before_action :set_max_step_index

  include TokenInvitable
  prepend_before_action :store_invitation_in_session_and_redirect_for_allowlisted_actions

  def new
    @rdv_wizard = rdv_wizard_for(current_user, query_params)
    @rdv = @rdv_wizard.rdv
    authorize(@rdv, policy_class: User::RdvPolicy)
    if @rdv_wizard.creneau.present?
      render current_step
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
      redirect_to new_users_rdv_wizard_step_path(@rdv_wizard.to_query.merge(step: next_step_number))
    else
      render current_step
    end
  end

  protected

  def store_invitation_in_session_and_redirect_for_allowlisted_actions
    return true if params[:invitation_token].blank?

    Sentry.capture_message("Invitation used unexpectedly on #{params[:controller]}##{params[:action]}")
    store_invitation_in_session_and_redirect
  end

  def steps
    if current_user.signed_in_with_invitation_token?
      UserRdvWizard::INVITATION_STEPS
    else
      UserRdvWizard::STEPS
    end
  end

  def current_step
    return steps.first if params[:step].blank?

    step = "step#{params[:step]}"
    raise "Invalid step: #{step.inspect}" unless step.in?(steps)

    step
  end

  def next_step_number
    steps[steps.index(current_step) + 1].last
  end

  def set_current_step_index
    @current_step_index = steps.index(current_step) + 2
  end

  def set_max_step_index
    @max_step_index = steps.size + 1
  end

  def rdv_wizard_for(current_user, request_params)
    klass = "UserRdvWizard::#{current_step.camelize}".constantize
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
