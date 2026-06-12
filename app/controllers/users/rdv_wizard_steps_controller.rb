class Users::RdvWizardStepsController < UserAuthController
  layout "application_base"

  RDV_PERMITTED_PARAMS = [:starts_at, :motif_id, :context, { user_ids: [] }].freeze
  EXTRA_PERMITTED_PARAMS = [
    *WebSearchContext::ADDRESS_SELECTION_PARAMS,
    :lieu_id, :where, :created_user_id, :rdv_collectif_id, :user_selected_organisation_id,
    :public_link_organisation_id, :duration, :ants_pre_demandes_count,
    { organisation_ids: [], referent_ids: [], external_organisation_ids: [] },
  ].freeze

  before_action :set_skip_proches_step

  include TokenInvitable

  def new
    @rdv_builder = Users::RdvBuilder.new(current_user, query_params)
    @rdv_wizard = @rdv_builder # pour les vues qui utilisent encore ce nom de variable
    @rdv = @rdv_builder.rdv
    return if redirect_to_prendre_rdv_path_if_creneau_unavailable
    return if prevent_if_proconnect_restriction_not_respected

    @rdv_booking_form = Users::RdvBookingForm.new(user: current_user, rdv_builder: @rdv_builder, domain: current_domain) if step1?
    authorize(@rdv, policy_class: User::RdvPolicy)
    if @rdv_builder.creneau.present?
      render current_step[:name], locals: { current_step:, max_step: steps.size, next_step: }
    else
      flash[:error] = "Ce créneau n'est plus disponible. Veuillez en sélectionner un autre."
      redirect_to(prendre_rdv_path(@rdv_builder.to_query))
    end
  end

  def create
    @rdv_builder = Users::RdvBuilder.new(current_user, rdv_params)
    @rdv_wizard = @rdv_builder
    @rdv = @rdv_builder.rdv
    return if redirect_to_prendre_rdv_path_if_creneau_unavailable

    if step1?
      @rdv_booking_form = Users::RdvBookingForm.new(user: current_user, rdv_builder: @rdv_builder, domain: current_domain, user_attributes: user_params[:user].to_h.symbolize_keys)
      if @rdv_booking_form.save
        redirect_to new_users_rdv_wizard_step_path(@rdv_builder.to_query.merge(step: next_step[:number]))
      else
        render "step1", locals: { current_step:, max_step: steps.size, next_step: }
      end
    else
      # dans les faits, uniquement pour la step 2 car la step3 pointe vers rdvs#create
      redirect_to new_users_rdv_wizard_step_path(@rdv_builder.to_query.merge(step: next_step[:number]))
    end
  end

  private

  def prevent_if_proconnect_restriction_not_respected
    if @rdv.motif&.organisation&.online_booking_only_proconnect? && current_user.pro_connect_openid_sub.blank?
      skip_authorization
      flash[:error] = "Ce motif de rendez-vous est réservé aux professionnels. " \
                      "Si vous êtes un professionnel et que vous souhaitez prendre rendez-vous, merci de vous déconnecter et de recommencer votre demande en utilisant ProConnect."
      redirect_back(fallback_location: root_path)
    end
  end

  protected

  # On ne propose pas de prendre RDV pour un proche si :
  # - l'usager est invité (c'est lui qui est concerné)
  # - l'usager est connecté via ProConnect (professionnel)
  def set_skip_proches_step
    @skip_proches_step = current_user.signed_in_with_invitation_token? || current_user.pro_connect_openid_sub
  end

  def steps
    steps = {
      step1: {
        name: "step1",
        number: 1,
        title: "Vos informations",
        next_step: @skip_proches_step ? :step3 : :step2,
        stepper_index: 1,
      },
      step2: {
        name: "step2",
        number: 2,
        title: "Choix de l’usager",
        next_step: :step3,
        stepper_index: 2,
      },
      step3: {
        name: "step3",
        number: 3,
        title: "Confirmation",
        stepper_index: @skip_proches_step ? 2 : 3,
      },
    }

    steps.delete(:step2) if @skip_proches_step

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

  def step1? = current_step[:name] == "step1"

  def rdv_params
    params.require(:rdv).permit(*RDV_PERMITTED_PARAMS).merge(params.permit(*EXTRA_PERMITTED_PARAMS))
  end

  def query_params
    result = params.permit(*RDV_PERMITTED_PARAMS, *EXTRA_PERMITTED_PARAMS)
    result[:user_ids] = [result[:created_user_id]] if result[:created_user_id].present?
    result
  end

  def user_params
    params.permit(user: [
                    :first_name,
                    :last_name,
                    :birth_name,
                    :phone_number,
                    :birth_date,
                    :email,
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

  def redirect_to_prendre_rdv_path_if_creneau_unavailable
    if !@rdv_builder.creneau || !@rdv_builder.rdv.remaining_seats?
      flash[:error] = "Ce créneau n'est plus disponible. Veuillez en sélectionner un autre."
      skip_authorization
      redirect_to prendre_rdv_path(@rdv_builder.to_query_for_search_redirection)
      true
    end
  end
end
