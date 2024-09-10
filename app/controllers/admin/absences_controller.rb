class Admin::AbsencesController < AgentAuthController
  respond_to :html, :json

  before_action :set_absence, only: %i[edit update destroy]
  before_action :build_absence, only: [:create]
  before_action :set_agent

  def index
    absences = policy_scope(Absence)
      .where(agent_id: filter_params[:agent_id])
      .includes(:agent)
      .by_starts_at
      .page(page_number)

    @absences = params[:current_tab] == "expired" ? absences.expired : absences.not_expired
    @display_tabs = absences.expired.any? || params[:current_tab] == "expired"
  end

  def new
    if params[:duplicate_absence_id].present?
      original_abs = Absence.find(params[:duplicate_absence_id])
      defaults = original_abs.slice(:title, :first_day, :start_time, :end_day, :end_time, :recurrence)
    else
      defaults = {
        first_day: Time.zone.tomorrow,
        start_time: Tod::TimeOfDay.new(9),
        end_time: Tod::TimeOfDay.new(18),
      }
    end

    @absence = Absence.new(agent: @agent, **defaults)

    authorize(@absence)
  end

  def edit
    authorize(@absence)
  end

  def create
    authorize(@absence)
    if @absence.save
      Agents::AbsenceMailer.with(absence: @absence).absence_created.deliver_later if @agent.absence_notification_level == "all"
      flash[:notice] = t(".absence_created")
      redirect_to admin_organisation_agent_absences_path(current_organisation, @absence.agent_id)
    else
      render :new
    end
  end

  def update
    authorize(@absence)
    if @absence.update(absence_params)
      Agents::AbsenceMailer.with(absence: @absence).absence_updated.deliver_later if @agent.absence_notification_level == "all"
      flash[:notice] = t(".absence_updated")
      redirect_to admin_organisation_agent_absences_path(current_organisation, @absence.agent_id)
    else
      render :edit
    end
  end

  def destroy
    authorize(@absence)
    if @absence.destroy
      # On passe l'absence au job sous forme sérialisée puisqu'elle n'existe plus en base.
      Agents::AbsenceMailer.with(absence: @absence.attributes).absence_destroyed.deliver_later if @agent.absence_notification_level == "all"
      flash[:notice] = t(".absence_deleted")
      redirect_to admin_organisation_agent_absences_path(current_organisation, @absence.agent_id)
    else
      render :edit
    end
  end

  private

  def set_absence
    @absence = policy_scope(Absence)
      .find(params[:id])
  end

  def build_absence
    @absence = Absence.new(absence_params)
  end

  def set_agent
    @agent = filter_params[:agent_id].present? ? policy_scope(Agent, policy_scope_class: Agent::AgentPolicy::Scope).find(filter_params[:agent_id]) : @absence.agent
  end

  def absence_params
    params.require(:absence).permit(:title, :agent_id, :first_day, :end_day, :start_time, :end_time, :recurrence)
  end

  def filter_params
    params.permit(:start, :end, :agent_id, :page, :current_tab)
  end
end
