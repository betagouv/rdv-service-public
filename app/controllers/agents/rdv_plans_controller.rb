class Agents::RdvPlansController < AgentAuthController
  layout "application"

  def new_from_calendar
    @rdv_plan = RdvPlan.new(
      planning_agent: current_agent,
      user_id: params[:user_id]
    )

    authorize @rdv_plan, :edit?, policy_class: Agent::RdvPlanPolicy
  end

  def modalites
    @rdv_plan = RdvPlan.new(
      planning_agent: current_agent,
      starts_at: params[:starts_at],
      user_id: params[:user_id],
      duration_in_minutes: 30
    )

    authorize @rdv_plan, :edit?, policy_class: Agent::RdvPlanPolicy
  end

  def create_from_modalites
    rdv_plan_params = params.require(:rdv_plan)

    location_type, lieu_id = rdv_plan_params["modalite"].split("-")

    @rdv_plan = RdvPlan.new(
      planning_agent: current_agent,
      rdv_agent: current_agent,
      location_type: location_type,
      lieu_id: lieu_id
    )
    @rdv_plan.assign_attributes(rdv_plan_params.permit(:starts_at, :duration_in_minutes, :user_id))

    authorize @rdv_plan, :edit?, policy_class: Agent::RdvPlanPolicy

    if @rdv_plan.save
      redirect_to edit_motif_from_calendar_agents_rdv_plan_path(@rdv_plan)
    else
      render "modalites"
    end
  end

  def edit_motif_from_calendar
    find_rdv_plan
    @motifs = current_agent.motifs.where(organisation_id: current_agent.roles.select(:organisation_id))
      .where(location_type: @rdv_plan.location_type)
  end

  def update_motif_from_calendar
    find_rdv_plan
  end

  def edit_user_from_calendar
    find_rdv_plan
  end

  # Version recherche de créneaux

  def new
    @rdv_plan = RdvPlan.new(
      planning_agent: current_agent,
      user_id: params[:user_id]
    )

    authorize @rdv_plan, :edit?, policy_class: Agent::RdvPlanPolicy
    render "edit_motif"
  end

  def create
    @rdv_plan = RdvPlan.create!(
      planning_agent: current_agent,
      user_id: params.require(:rdv_plan)[:user_id]
    )

    params[:id] = @rdv_plan.id # audacieux
    update_motif
  end

  def edit_motif
    find_rdv_plan
  end

  def update_motif
    find_rdv_plan

    # On réinitialise le lieu si on change le motif
    if params.dig(:rdv_plan, :motif_id).to_i != @rdv_plan.motif_id
      @rdv_plan.lieu_id = nil
    end

    @rdv_plan.assign_attributes(params.require(:rdv_plan).permit(:motif_id))

    if @rdv_plan.save
      if @rdv_plan.motif.requires_lieu?
        if @rdv_plan.organisation.lieux.enabled.count > 1
          redirect_to edit_lieu_agents_rdv_plan_path(@rdv_plan)
        else
          @rdv_plan.update(lieu: @rdv_plan.organisation.lieux.enabled.first)

          search_form = AgentCreneauxSearchForm.build_from(@rdv_plan)

          @next_availabilities = get_next_availabilities(search_form)

          # TODO: gérer le cas de pas de créneaux
          redirect_to edit_creneau_agents_rdv_plan_path(@rdv_plan, from: @next_availabilities.first.starts_at.to_date)
        end
      else
        redirect_to edit_creneau_agents_rdv_plan_path(@rdv_plan)
      end
    else
      render "edit_motif"
    end
  end

  def edit_lieu
    find_rdv_plan
    @rdv_plan.lieu_id = nil

    @search_form = AgentCreneauxSearchForm.build_from(@rdv_plan)

    @next_availabilities = get_next_availabilities(@search_form)
  end

  def update_lieu
    find_rdv_plan
    if @rdv_plan.update(params.require(:rdv_plan).permit(:lieu_id))
      redirect_to edit_creneau_agents_rdv_plan_path(@rdv_plan, from: params.dig(:rdv_plan, :from_date))
    else
      render "edit_lieu"
    end
  end

  def edit_creneau
    find_rdv_plan
    @search_form = AgentCreneauxSearchForm.build_from(@rdv_plan, from_date: params[:from])

    @results = if @search_form.motif.individuel?
                 CreneauxSearch::ForAgent.new(@search_form).build_result
               else
                 CreneauxSearch::RdvCollectifForAgent.new(@search_form).slot_search
               end
  end

  def update_creneau
    find_rdv_plan
    if @rdv_plan.update(params.require(:rdv_plan).permit(:starts_at, :rdv_agent_id))
      redirect_to edit_user_agents_rdv_plan_path(@rdv_plan)
    else
      render "edit_creneau"
    end
  end

  def edit_user
    find_rdv_plan
  end

  def create_rdv
    find_rdv_plan
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
    find_rdv_plan
    @rdv = @rdv_plan.rdv
  end

  private

  def get_next_availabilities(search_form)
    if search_form.motif.individuel?
      CreneauxSearch::ForAgent.new(search_form).next_availabilities
    else
      CreneauxSearch::RdvCollectifForAgent.new(search_form).next_availabilities
    end
  end

  def find_rdv_plan
    @rdv_plan = current_agent.rdv_plans.find(params[:id])
    authorize @rdv_plan, :edit?, policy_class: Agent::RdvPlanPolicy
  end

  def pundit_user
    current_agent
  end
end
