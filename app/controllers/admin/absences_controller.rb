# frozen_string_literal: true

class Admin::AbsencesController < AgentAuthController
  respond_to :html, :json

  before_action :set_absence, only: %i[show edit update destroy]
  before_action :build_absence, only: [:create]
  before_action :set_agent

  def index
    absences = policy_scope(Absence)
      .where(organisation: current_organisation)
      .where(agent_id: filter_params[:agent_id])
      .includes(:organisation)
      .by_starts_at
      .page(filter_params[:page])
    @current_tab = filter_params[:current_tab]
    @absences = params[:current_tab] == "expired" ? absences.past : absences.future
    @display_tabs = absences.past.any? || params[:current_tab] == "expired"
  end

  def new
    @absence = Absence.new(organisation: current_organisation, agent: @agent)
    if params[:duplicate_absence_id].present?
      original_abs = Absence.find(params[:duplicate_absence_id])
      defaults = original_abs.slice(:title, :first_day, :start_time, :end_day, :end_time, :recurrence)
    else
      defaults = {
        first_day: Time.zone.tomorrow,
        start_time: Tod::TimeOfDay.new(9),
        end_time: Tod::TimeOfDay.new(18)
      }
    end

    @absence = Absence.new(organisation: current_organisation, agent: @agent, **defaults)

    authorize(@absence)
  end

  def edit
    authorize(@absence)
  end

  def create
    @absence.organisation = current_organisation
    authorize(@absence)
    if @absence.save
      Agents::AbsenceMailer.absence_created(Admin::Ics::Absence.create_payload(@absence)).deliver_later
      flash[:notice] = "L'absence a été créée."
      redirect_to admin_organisation_agent_absences_path(@absence.organisation_id, @absence.agent_id)
    else
      render :edit
    end
  end

  def update
    authorize(@absence)
    if @absence.update(absence_params)
      Agents::AbsenceMailer.absence_updated(Admin::Ics::Absence.update_payload(@absence)).deliver_later
      flash[:notice] = "L'absence a été modifiée."
      redirect_to admin_organisation_agent_absences_path(@absence.organisation_id, @absence.agent_id)
    else
      render :edit
    end
  end

  def destroy
    authorize(@absence)
    if @absence.destroy
      Agents::AbsenceMailer.absence_destroyed(Admin::Ics::Absence.destroy_payload(@absence)).deliver_later
      flash[:notice] = "L'absence a été supprimée."
      redirect_to admin_organisation_agent_absences_path(@absence.organisation_id, @absence.agent_id)
    else
      render :edit
    end
  end

  private

  def set_absence
    @absence = policy_scope(Absence)
      .where(organisation: current_organisation)
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
    params.permit(:start, :end, :organisation_id, :agent_id, :page, :current_tab)
  end
end
