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
    return if redirect_to_prendre_rdv_path_if_creneau_unavailable

    @rdv_wizard = @rdv_builder # pour les vues qui utilisent encore ce nom de variable
    @rdv = @rdv_builder.rdv
    @rdv_booking_form = Users::RdvBookingForm.new(user: current_user, rdv_builder: @rdv_builder, domain: current_domain)
    @rdv_booking_form.booking_for_proche = true if params[:booking_for_proche] == "1"
    authorize(@rdv, policy_class: User::RdvPolicy)
  end

  def create
    skip_authorization
    @rdv_builder = Users::RdvBuilder.new(current_user, rdv_params)
    return if redirect_to_prendre_rdv_path_if_creneau_unavailable

    @rdv_wizard = @rdv_builder
    @rdv = @rdv_builder.rdv
    @rdv_booking_form = Users::RdvBookingForm.new(
      user: current_user, rdv_builder: @rdv_builder,
      domain: current_domain, user_attributes: user_params[:user].to_h.symbolize_keys
    )

    return if render_new_if_toggling_proches_without_js

    if @rdv_booking_form.save
      flash[:success] = (@rdv_booking_form.rdv.collectif? ? "Participation confirmée" : t("users.rdvs.create.rdv_confirmed"))
      set_user_name_initials_verified
      redirect_to users_rdv_path(@rdv_booking_form.rdv, invitation_token: @rdv_booking_form.invitation_token)
    else
      flash[:error] = "Une erreur a empêché la confirmation de votre RDV"
      render :new
    end
  end

  def redirect_to_prendre_rdv_path_if_creneau_unavailable
    if !@rdv_builder.creneau || !@rdv_builder.rdv.remaining_seats?
      flash[:error] = "Ce créneau n'est plus disponible. Veuillez en sélectionner un autre."
      skip_authorization
      redirect_to prendre_rdv_path(@rdv_builder.to_query)
      true
    end
  end

  def render_new_if_toggling_proches_without_js
    # la versions sans JS affiche deux boutons submit supplémentaires avec des name différents
    # lorsque l'usager clique dessus, on toggle le form et on re-render le #new
    # cela permet de conserver ce qu'il avait déjà renseigné dans les champs du formulaire
    if params[:enable_proche_section].present? || params[:disable_proche_section].present?
      @rdv_booking_form.booking_for_proche =
        if params[:enable_proche_section].present?
          true
        elsif params[:disable_proche_section].present?
          false
        end
      render :new
      true
    end
  end

  protected

  # On ne propose pas de prendre RDV pour un proche si :
  # - l'usager est invité (c'est lui qui est concerné)
  # - l'usager est connecté via ProConnect (professionnel)
  def set_skip_proches_step
    @skip_proches_step = current_user.signed_in_with_invitation_token? || current_user.pro_connect_openid_sub
  end

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
                    :booking_for_proche,
                    :enable_proche_section,
                    :disable_proche_section,
                    :selected_proche,
                    { user_profiles_attributes: %i[logement id organisation_id] },
                    { proches: {} },
                  ])
  end
end
