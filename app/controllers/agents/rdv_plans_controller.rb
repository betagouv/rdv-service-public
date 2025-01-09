class Agents::RdvPlansController < AgentAuthController
  layout "application"
  before_action :find_rdv_plan

  def edit_starts_at; end

  def update_starts_at
    if @rdv_plan.update(params.require(:rdv_plan).permit(:starts_at))
      redirect_to edit_modalites_agents_rdv_plan_path(@rdv_plan)
    else
      render "edit_modalites"
    end
  end

  def edit_modalites; end

  def update_modalites
    rdv_plan_params = params.require(:rdv_plan)

    location_type, lieu_id = rdv_plan_params["modalite"].split("-")

    @rdv_plan.assign_attributes(
      rdv_agent: current_agent,
      location_type: location_type,
      lieu_id: lieu_id
    )
    @rdv_plan.assign_attributes(rdv_plan_params.permit(:starts_at, :duration_in_minutes, :user_id))

    if @rdv_plan.save
      redirect_to edit_motif_agents_rdv_plan_path(@rdv_plan)
    else
      render "edit_modalites"
    end
  end

  def edit_motif
    @motifs = current_agent.motifs.where(organisation_id: current_agent.roles.select(:organisation_id))
      .where(location_type: @rdv_plan.location_type)
  end

  def update_motif
    if @rdv_plan.update(params.require(:rdv_plan).permit(:motif_id))
      redirect_to edit_user_from_calendar_agents_rdv_plan_path(@rdv_plan)
    else
      render "edit_motif_from_calendar"
    end
  end

  def edit_user; end

  def create_rdv
    rdv_plan_params = params.require(:rdv_plan)

    user_attributes = rdv_plan_params.require(:user).permit(:email, :phone_number)
    participation_attributes = if @rdv_plan.motif.visible_and_notified?
                                 rdv_plan_params.require(:participation).permit(
                                   :send_lifecycle_notifications, :send_reminder_notification
                                 )
                               else
                                 { send_lifecycle_notifications: false, send_reminder_notification: false }
                               end

    rdv = @rdv_plan.create_rdv(user_attributes:, participation_attributes:)

    if rdv.valid?
      flash[:success] = "Le rendez-vous a été créé."
      redirect_to rdv_agents_rdv_plan_path(@rdv_plan)
    else
      flash[:error] = rdv.errors.full_messages.to_sentence
      redirect_to edit_user_agents_rdv_plan_path(@rdv_plan)
    end
  end

  def rdv
    @rdv = @rdv_plan.rdv
  end

  private

  def find_rdv_plan
    @rdv_plan = current_agent.rdv_plans.find(params[:id])
    authorize @rdv_plan, :edit?, policy_class: Agent::RdvPlanPolicy
  end

  def pundit_user
    current_agent
  end
end
