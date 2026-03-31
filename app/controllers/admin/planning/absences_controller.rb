class Admin::Planning::AbsencesController < AgentAuthController
  include Admin::Planning::SetAgentsConcern
  respond_to :html, :json

  before_action :set_absence, only: %i[edit update destroy]
  before_action :build_absence, only: [:create]
  before_action :set_agents
  before_action { @planning_layout = true }

  def index
    # TODO: retirer ce code 2 semaines après la mise en prod, il affiche une pastille sur les nouveaux onglets.
    unless current_agent.feature_enabled?(Agent::FeatureFlags::NEW_PLANNING)
      current_agent.update_columns(feature_flags: current_agent.feature_flags.merge("new_planning" => true)) # rubocop:disable Rails/SkipsModelValidations
    end

    @multiple_agents_makes_sense = true
    render :multi_agents_index and return if @agents.size > 1

    absences = policy_scope(Absence, policy_scope_class: Agent::AbsencePolicy::Scope)
      .where(agent: @agent)
      .includes(:agent)
      .page(page_number)

    absences = if params[:current_tab] == "expired"
                 absences.by_starts_at(:desc)
               else
                 absences.by_starts_at(:asc)
               end

    @absences = params[:current_tab] == "expired" ? absences.expired : absences.not_expired
    @display_tabs = absences.expired.any? || params[:current_tab] == "expired"
  end

  def new
    if params[:duplicate_absence_id].present?
      original_abs = Absence.find(params[:duplicate_absence_id])
      authorize(original_abs, :show?, policy_class: Agent::AbsencePolicy)
      defaults = original_abs.slice(:title, :first_day, :start_time, :end_day, :end_time, :recurrence)
    else
      defaults = {
        first_day: Time.zone.tomorrow,
        start_time: Tod::TimeOfDay.new(9),
        end_time: Tod::TimeOfDay.new(18),
      }
    end

    @absence = Absence.new(agent: @agent, **defaults)

    authorize(@absence, policy_class: Agent::AbsencePolicy)
  end

  def edit
    authorize(@absence, policy_class: Agent::AbsencePolicy)
  end

  def create
    authorize(@absence, policy_class: Agent::AbsencePolicy)
    if @absence.save
      Notifiers::AbsenceCreated.new(@absence).perform
      flash[:success] = t(".absence_created")
      redirect_to admin_organisation_planning_absences_path(current_organisation, agent_id: @absence.agent_id)
    else
      render :new
    end
  end

  def update
    authorize(@absence, policy_class: Agent::AbsencePolicy)
    if @absence.update(absence_params)
      Notifiers::AbsenceUpdated.new(@absence).perform
      flash[:success] = t(".absence_updated")
      redirect_to admin_organisation_planning_absences_path(current_organisation, agent_id: @absence.agent_id)
    else
      render :edit
    end
  end

  def destroy
    authorize(@absence, policy_class: Agent::AbsencePolicy)
    if @absence.destroy
      Notifiers::AbsenceDestroyed.new(@absence).perform
      flash[:notice] = t(".absence_deleted")
      redirect_to admin_organisation_planning_absences_path(current_organisation, agent_id: @absence.agent_id)
    else
      render :edit
    end
  end

  private

  def set_absence
    @absence = policy_scope(Absence, policy_scope_class: Agent::AbsencePolicy::Scope)
      .find(params[:id])
  end

  def build_absence
    @absence = Absence.new(absence_params)
  end

  def set_agents
    if @absence&.agent
      @agent = @absence.agent
      @agents = [@agent]
    else
      super
    end
  end

  def absence_params
    params.require(:absence).permit(:title, :agent_id, :first_day, :end_day, :start_time, :end_time, :recurrence)
  end
end
