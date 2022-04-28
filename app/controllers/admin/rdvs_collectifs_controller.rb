# frozen_string_literal: true

class Admin::RdvsCollectifsController < AgentAuthController
  def index
    @motifs = policy_scope(Motif).available_motifs_for_organisation_and_agent(current_organisation, current_agent).collectif

    @rdvs = policy_scope(Rdv).where(organisation: current_organisation).collectif
    @rdvs = @rdvs.order(starts_at: :asc).page(params[:page])

    @form = Admin::RdvCollectifSearchForm.new(params.permit(:motif_id, :organisation_id, :from_date, :with_remaining_seats))

    @rdvs = @form.filter(@rdvs)
  end

  def new
    motif = policy_scope(Motif).find(params[:motif_id])
    @rdv = Rdv.new(organisation: current_organisation, motif: motif, duration_in_min: motif.default_duration_in_min)

    if params[:duplicated_rdv_id]
      duplicated_rdv = policy_scope(Rdv).find(params[:duplicated_rdv_id])

      new_rdv_attributes = duplicated_rdv.attributes.symbolize_keys.slice(*create_attribute_names)
      @rdv.assign_attributes(new_rdv_attributes)
      @rdv.agents = duplicated_rdv.agents
    end
    authorize(@rdv)
  end

  def create
    @rdv = Rdv.new(organisation: current_organisation, users_count: 0)
    authorize(@rdv, :new?)

    if @rdv.update(create_params)
      Notifiers::RdvCreated.perform_with(@rdv, current_agent)
      flash[:notice] = "#{@rdv.motif.name} créé"
      redirect_to admin_organisation_rdvs_collectifs_path(current_organisation)
    else
      render :new
    end
  end

  def edit
    @rdv = Rdv.find(params[:id])

    authorize(@rdv)

    @add_user_ids = params[:add_user].to_a + params[:user_ids].to_a
    users_to_add = User.where(id: @add_user_ids)
    @rdv_users_to_add = users_to_add.ids.map { @rdv.rdvs_users.build(user_id: _1) }
  end

  def update
    @rdv = Rdv.find(params[:id])
    authorize(@rdv, :update?)

    previous_participant_ids = @rdv.participants_with_life_cycle_notification_ids

    if @rdv.update(update_users_params)
      flash[:notice] = "Participants mis à jour"
      Notifiers::RdvCollectifParticipations.perform_with(@rdv, current_agent, previous_participant_ids)
      redirect_to admin_organisation_rdvs_collectifs_path(current_organisation)
    else
      render :edit
    end
  end

  private

  def create_attribute_names
    %i[starts_at duration_in_min lieu_id name max_participants_count context motif_id]
  end

  def create_params
    params.require(:rdv).permit(*create_attribute_names, agent_ids: [])
  end

  def update_users_params
    params.require(:rdv).permit(
      user_ids: [],
      rdvs_users_attributes: %i[user_id send_lifecycle_notifications send_reminder_notification id _destroy]
    )
  end
end
