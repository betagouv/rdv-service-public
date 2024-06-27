class Admin::RdvsCollectifsController < AgentAuthController
  include RdvsHelper

  def index
    @motifs = Agent::MotifPolicy::UseScope.apply(current_agent, Motif.active).available_motifs_for_organisation_and_agent(current_organisation, current_agent).collectif

    @rdvs = policy_scope(Rdv).where(organisation: current_organisation).collectif
    @rdvs = @rdvs.order(starts_at: :asc).page(page_number)

    @form = Admin::RdvCollectifSearchForm.new(params.permit(:motif_id, :organisation_id, :from_date, :with_remaining_seats))

    @rdvs = @form.filter(@rdvs)
  end

  def new
    motif = Agent::MotifPolicy::UseScope.apply(current_agent, Motif.all).find(params[:motif_id])
    @rdv_form = Admin::NewRdvForm.new(pundit_user, organisation: current_organisation, motif: motif, duration_in_min: motif.default_duration_in_min)
    @rdv = @rdv_form.rdv

    if params[:duplicated_rdv_id]
      duplicated_rdv = policy_scope(Rdv).find(params[:duplicated_rdv_id])

      new_rdv_attributes = duplicated_rdv.attributes.symbolize_keys.slice(*create_attribute_names)
      @rdv.assign_attributes(new_rdv_attributes)
      @rdv.agents = duplicated_rdv.agents
    end
    authorize(@rdv)
  end

  def create
    @rdv_form = Admin::NewRdvForm.new(pundit_user, create_params.merge(organisation: current_organisation))
    @rdv = @rdv_form.rdv

    authorize(@rdv, :new?)
    if @rdv_form.save
      Notifiers::RdvCreated.perform_with(@rdv, current_agent)
      redirect_to admin_organisation_rdvs_collectifs_path(current_organisation), notice: I18n.t("admin.rdvs.message.success.create")
    else
      render :new
    end
  end

  def edit
    @rdv = Rdv.find(params[:id])

    authorize(@rdv)

    @add_user_ids = params[:add_user].to_a + params[:user_ids].to_a
    users_to_add = User.where(id: @add_user_ids)
    @participations_to_add = users_to_add.ids.map { @rdv.participations.build(user_id: _1, created_by: current_agent) }
  end

  def update
    @rdv = Rdv.find(params[:id])
    authorize(@rdv, :update?)

    if @rdv.update_and_notify(current_agent, update_users_params)
      flash[:notice] = "Participants mis à jour"
      redirect_to admin_organisation_rdvs_collectifs_path(current_organisation)
    else
      render :edit
    end
  end

  private

  def create_attribute_names
    %i[starts_at duration_in_min lieu_id name max_participants_count context motif_id ignore_benign_errors]
  end

  def create_attributes_rdvs
    [agent_ids: [], lieu_attributes: %i[name address latitude longitude]]
  end

  def create_params
    allowed_params = params.require(:rdv).permit(*create_attribute_names, *create_attributes_rdvs)
    return allowed_params if params[:rdv][:lieu_id].present?

    allowed_params.to_h.deep_merge(lieu_attributes: { organisation: current_organisation, availability: :single_use })
  end

  def update_users_params
    params.require(:rdv).permit(
      user_ids: [],
      participations_attributes: %i[user_id send_lifecycle_notifications send_reminder_notification id _destroy]
    )
  end
end
