class VisitorRdvWizardController < ApplicationController
  RDV_PERMITTED_PARAMS = [:starts_at, :motif_id, :context, { user_ids: [] }].freeze

  EXTRA_PERMITTED_PARAMS = [
    *WebSearchContext::ADDRESS_SELECTION_PARAMS,
    :lieu_id, :where, :rdv_collectif_id, :user_selected_organisation_id,
    :public_link_organisation_id, :duration, :ants_pre_demandes_count,
    { organisation_ids: [], referent_ids: [], external_organisation_ids: [] },
  ].freeze

  def user_infos
    skip_authorization
    @rdv_wizard = VisitorRdvWizard.new(query_params)
    @rdv = @rdv_wizard.rdv
    # authorize(@rdv, policy_class: User::RdvPolicy)
    if @rdv_wizard.creneau.nil?
      flash[:error] = "Ce créneau n'est plus disponible. Veuillez en sélectionner un autre."
      redirect_to(prendre_rdv_path(@rdv_wizard.to_query))
    end
  end

  def save_user_infos
    skip_authorization
    @rdv_wizard = VisitorRdvWizard.new(query_params.merge(params.require(:visitor_rdv_wizard).permit(user: %i[first_name last_name phone_number])))
    @rdv = @rdv_wizard.rdv
    if @rdv_wizard.valid?
      rdv_plan = @rdv_wizard.build_rdv_plan
      if rdv_plan.user.save && rdv_plan.save
        redirect_to visitor_rdv_wizard_show_confirm_path(rdv_plan_id: rdv_plan.id)
      else
        render :user_infos
      end
    else
      render :user_infos
    end
  end

  def show_confirm
    skip_authorization
    @rdv_plan = RdvPlan.find(params[:rdv_plan_id])
    # @rdv_wizard = VisitorRdvWizard.new()
    # @rdv = @rdv_wizard.rdv
  end

  def send_sms
    skip_authorization
    @rdv_plan = RdvPlan.find(params[:rdv_plan_id])
    # send SMS
    redirect_to visitor_rdv_wizard_show_confirm_sms_path(rdv_plan_id: @rdv_plan.id)
  end

  def show_confirm_sms
    skip_authorization
    @rdv_plan = RdvPlan.find(params[:rdv_plan_id])
    @form = VisitorConfirmForm.new(rdv_plan_id: @rdv_plan.id)
  end

  def confirm_sms
    @rdv_plan = RdvPlan.find(params[:visitor_confirm_form][:rdv_plan_id])
    @form = VisitorConfirmForm.new(rdv_plan_id: @rdv_plan.id, code: params[:visitor_confirm_form][:code])
    if @form.valid?
      rdv = @rdv_plan.create_rdv_visitor
      if rdv
        sign_in_user_restricted(rdv)
        redirect_to users_rdv_path(rdv), flash: { success: "Votre RDV est confirmé" }
      else
        render :show_confirm_sms
      end
    else
      render :show_confirm_sms
    end
  end

  protected

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

  include TokenInvitable

  def sign_in_user_restricted(rdv)
    participation = rdv.participations.first
    user = participation.user
    session[:invitation] = { invitation_token: participation[:restricted_auth_token], expires_at: 10.minutes.from_now }
    sign_in_with_session_token
    cookies.encrypted["user_name_initials_verified_#{user.id}"] = { value: true, expires: 10.minutes.from_now }
  end
end
