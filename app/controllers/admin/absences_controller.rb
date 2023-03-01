# frozen_string_literal: true

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
      .page(filter_params[:page])

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
      absence_mailer.absence_created.deliver_later if @agent.absence_notification_level == "all"
      flash[:notice] = t(".busy_time_created")
      redirect_to admin_organisation_agent_absences_path(current_organisation, @absence.agent_id)
    else
      render :edit
    end
  end

  def update
    authorize(@absence)
    if @absence.update(absence_params)
      absence_mailer.absence_updated.deliver_later if @agent.absence_notification_level == "all"
      flash[:notice] = t(".busy_time_updated")
      redirect_to admin_organisation_agent_absences_path(current_organisation, @absence.agent_id)
    else
      render :edit
    end
  end

  def destroy
    authorize(@absence)
    if @absence.destroy
      # NOTE: the destruction email is sent synchronously (not in a job) to ensure @absence still exists.
      absence_mailer.absence_destroyed.deliver_now if @agent.absence_notification_level == "all"
      flash[:notice] = t(".busy_time_deleted")
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
    @agent = filter_params[:agent_id].present? ? policy_scope(Agent).find(filter_params[:agent_id]) : @absence.agent
  end

  def absence_params
    params.require(:absence).permit(:title, :agent_id, :first_day, :end_day, :start_time, :end_time, :recurrence)
  end

  def filter_params
    params.permit(:start, :end, :agent_id, :page, :current_tab)
  end

  def absence_mailer
    Agents::AbsenceMailer.with(absence: @absence)
  end
end
