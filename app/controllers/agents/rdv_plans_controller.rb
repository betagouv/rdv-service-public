class Agents::RdvPlansController < AgentAuthController
  layout "application"
  before_action :find_rdv_plan
  before_action :redirect_to_rdv, if: -> { @rdv_plan.rdv.present? }, except: [:rdv]

  def show
    if current_agent.organisations.any?
      redirect_to edit_starts_at_agents_rdv_plan_path(@rdv_plan)
    else
      redirect_to authenticated_agent_root_path
    end
  end

  def update_agent
    rdv_plan_params = params.require(:rdv_plan).permit(:rdv_agent_id)

    @rdv_plan.update!(rdv_plan_params)
    respond_to do |format|
      format.json do
        render json: {
          event_sources:,
          display_saturdays: @rdv_plan.rdv_agent.display_saturdays,
        }
      end
    end
  end

  def edit_starts_at
    @rdv_plan.starts_at = nil

    other_agents = policy_scope(Agent, policy_scope_class: Agent::AgentPolicy::Scope).active
      .joins(:organisations)
      .where(organisations: current_agent.organisations)
      .where.not(id: current_agent.id)

    render locals: { event_sources:, other_agents: }
  end

  def update_starts_at
    @rdv_plan.update!(params.require(:rdv_plan).permit(:starts_at))
    redirect_to edit_modalites_agents_rdv_plan_path(@rdv_plan)
  end

  def edit_modalites
    @available_location_types = available_motifs(@rdv_plan).pluck(:location_type)

    render locals: { event_sources: }
  end

  def update_modalites
    rdv_plan_params = params.require(:rdv_plan).permit(:starts_at, :modalite)

    if @rdv_plan.update(rdv_plan_params)
      redirect_to edit_motif_agents_rdv_plan_path(@rdv_plan)
    else
      render "edit_modalites", locals: { event_sources: }
    end
  end

  def edit_motif
    @motifs = available_motifs(@rdv_plan).ordered_by_name
    if @motifs.count == 1
      @rdv_plan.motif_id ||= @motifs.first.id
    end
    @rdv_plan.duration_in_minutes ||= @motifs.first.default_duration_in_min

    render locals: { event_sources: }
  end

  def update_motif
    rdv_plan_params = params.require(:rdv_plan).permit(:motif_id, :duration_in_minutes)

    if @rdv_plan.update(rdv_plan_params)
      redirect_to edit_user_agents_rdv_plan_path(@rdv_plan)
    else
      render "edit_motif_from_calendar", locals: { event_sources: }
    end
  end

  def edit_user
    render locals: { event_sources: }
  end

  def create_rdv
    rdv_plan_params = params.require(:rdv_plan)

    user_attributes = rdv_plan_params.require(:user).permit(:notification_email, :phone_number)

    # TODO: possible à mettre en commun ?
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

  def available_motifs(rdv_plan)
    motif_scope = Agent::MotifPolicy::Scope.new(
      current_agent,
      Motif.individuel.active
    ).resolve

    motif_scope.where(
      service: rdv_plan.rdv_agent.services + [nil],
      organisation_id: rdv_plan.rdv_agent.roles.select(:organisation_id)
    )
  end

  def find_rdv_plan
    @rdv_plan = RdvPlan.find(params[:id])
    authorize @rdv_plan, :edit?, policy_class: Agent::RdvPlanPolicy
  end

  def redirect_to_rdv
    # TODO: ajouter un flash ici?
    redirect_to rdv_agents_rdv_plan_path(@rdv_plan)
  end

  def pundit_user
    current_agent
  end

  def event_sources
    agent = @rdv_plan.rdv_agent
    organisation = agent.organisations.first

    event_sources = [
      admin_api_agenda_rdvs_path(agent_id: agent, organisation_id: organisation.id, format: :json),
      admin_api_agenda_absences_path(agent_id: agent, organisation_id: organisation.id, format: :json),
      admin_api_agenda_plage_ouvertures_path(agent_id: agent, organisation_id: organisation.id, mixed_with_rdvs: true, format: :json),
      OffDays.to_full_calendar_array,
    ]

    if @rdv_plan.starts_at
      event_sources << [
        {
          title: @rdv_plan.user.full_name,
          start: @rdv_plan.starts_at.as_json,
          end: (@rdv_plan.starts_at + (@rdv_plan.duration_in_minutes || 30).minutes).as_json,
          textColor: "white",
          backgroundColor: "#6a6af4",
        },
      ]
    end

    event_sources
  end
end
