# frozen_string_literal: true

class Admin::PlageOuverturesController < AgentAuthController
  respond_to :html, :json

  before_action :set_plage_ouverture, only: %i[show edit update destroy]
  before_action :build_plage_ouverture, only: [:create]
  before_action :set_agent

  def show
    authorize(@plage_ouverture)
  end

  def index
    @plage_ouvertures = policy_scope(PlageOuverture)
      .includes(:lieu, :organisation)
      .where(agent_id: filter_params[:agent_id])
      .order(updated_at: :desc)
      .where(expired_cached: filter_params[:current_tab] == "expired")
      .page(filter_params[:page])
    @current_tab = filter_params[:current_tab]
    @display_tabs = @plage_ouvertures.where(expired_cached: true).any? || params[:current_tab] == "expired"
  end

  def new
    @agent = Agent.find(params[:agent_id])
    if params[:duplicate_plage_ouverture_id].present?
      original_po = PlageOuverture.find(params[:duplicate_plage_ouverture_id])
      defaults = original_po.slice(:title, :lieu_id, :motif_ids, :first_day, :start_time, :end_time, :recurrence)
    else
      defaults = {
        first_day: Time.zone.now,
        start_time: Tod::TimeOfDay.new(9),
        end_time: Tod::TimeOfDay.new(12)
      }
    end
    @plage_ouverture = PlageOuverture.new(
      organisation: current_organisation,
      agent: @agent,
      **defaults
    )
    authorize(@plage_ouverture)
  end

  def edit
    authorize(@plage_ouverture)
  end

  def create
    @plage_ouverture.organisation = current_organisation
    authorize(@plage_ouverture)
    if @plage_ouverture.save
      Agents::PlageOuvertureMailer.plage_ouverture_created(Admin::Ics::PlageOuverture.create_payload(@plage_ouverture)).deliver_later
      flash[:notice] = "Plage d'ouverture créée"
      redirect_to admin_organisation_plage_ouverture_path(@plage_ouverture.organisation, @plage_ouverture)
    else
      render :new
    end
  end

  def update
    authorize(@plage_ouverture)
    if @plage_ouverture.update(plage_ouverture_params)
      Agents::PlageOuvertureMailer.plage_ouverture_updated(Admin::Ics::PlageOuverture.update_payload(@plage_ouverture)).deliver_later
      redirect_to admin_organisation_plage_ouverture_path(@plage_ouverture.organisation, @plage_ouverture), notice: "La plage d'ouverture a été modifiée."
    else
      render :edit
    end
  end

  def destroy
    authorize(@plage_ouverture)
    if @plage_ouverture.destroy
      Agents::PlageOuvertureMailer.plage_ouverture_destroyed(Admin::Ics::PlageOuverture.destroy_payload(@plage_ouverture)).deliver_later
      redirect_to admin_organisation_agent_plage_ouvertures_path(@plage_ouverture.organisation, @plage_ouverture.agent), notice: "La plage d'ouverture a été supprimée."
    else
      render :edit
    end
  end

  private

  def set_agent
    @agent = filter_params[:agent_id].present? ? policy_scope(Agent).find(filter_params[:agent_id]) : @plage_ouverture.agent
  end

  def set_plage_ouverture
    @plage_ouverture = PlageOuverture.find(params[:id])
  end

  def build_plage_ouverture
    @plage_ouverture = PlageOuverture.new(plage_ouverture_params)
  end

  def plage_ouverture_params
    params.require(:plage_ouverture).permit(:title, :agent_id, :first_day, :start_time, :end_time, :lieu_id, :recurrence, :active_warnings_confirm_decision, motif_ids: [])
  end

  def filter_params
    params.permit(:start, :end, :organisation_id, :agent_id, :page, :current_tab)
  end
end
