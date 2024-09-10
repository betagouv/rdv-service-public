class Admin::PlageOuverturesController < AgentAuthController
  respond_to :html, :json

  before_action :set_plage_ouverture, only: %i[show edit update destroy]
  before_action :build_plage_ouverture, only: [:create]
  before_action :set_agent

  def show
    authorize(@plage_ouverture)
  end

  def index
    all_plage_ouvertures = policy_scope(PlageOuverture)
      .includes(:lieu, :organisation, :motifs, :agent)
      .where(agent_id: filter_params[:agent_id])
      .order(updated_at: :desc)
    @plage_ouvertures = all_plage_ouvertures
      .where(expired_cached: filter_params[:current_tab] == "expired")
    @plage_ouvertures = @plage_ouvertures.page(page_number) unless params[:view_mode] == "calendar"
    @plage_ouvertures = @plage_ouvertures.search_by_text(params[:search]) if params[:search].present?
    @display_tabs = all_plage_ouvertures.where(expired_cached: true).any? || params[:current_tab] == "expired"
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
        end_time: Tod::TimeOfDay.new(12),
      }
    end
    @plage_ouverture = PlageOuverture.new(
      organisation: current_organisation,
      motif_ids: params[:motif_ids],
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

      Agents::PlageOuvertureMailer.with(plage_ouverture: @plage_ouverture).plage_ouverture_created.deliver_later if @agent.plage_ouverture_notification_level == "all"
      flash[:notice] = "Plage d'ouverture créée"
      redirect_to admin_organisation_plage_ouverture_path(@plage_ouverture.organisation, @plage_ouverture)
    else
      render :new
    end
  end

  def update
    authorize(@plage_ouverture)
    if @plage_ouverture.update(plage_ouverture_params)
      Agents::PlageOuvertureMailer.with(plage_ouverture: @plage_ouverture).plage_ouverture_updated.deliver_later if @agent.plage_ouverture_notification_level == "all"
      redirect_to admin_organisation_plage_ouverture_path(@plage_ouverture.organisation, @plage_ouverture), notice: "La plage d'ouverture a été modifiée."
    else
      render :edit
    end
  end

  def destroy
    authorize(@plage_ouverture)
    motif_ids = @plage_ouverture.motifs.ids
    if @plage_ouverture.destroy
      # On passe la plage au job sous forme sérialisée puisqu'elle n'existe plus en base.
      if @agent.plage_ouverture_notification_level == "all"
        plage_attributes = @plage_ouverture.attributes.merge(motif_ids: motif_ids)
        Agents::PlageOuvertureMailer.with(plage_ouverture: plage_attributes).plage_ouverture_destroyed.deliver_later
      end
      redirect_to admin_organisation_agent_plage_ouvertures_path(@plage_ouverture.organisation, @plage_ouverture.agent), notice: "La plage d'ouverture a été supprimée."
    else
      render :edit
    end
  end

  private

  def set_agent
    @agent = filter_params[:agent_id].present? ? policy_scope(Agent, policy_scope_class: Agent::AgentPolicy::Scope).find(filter_params[:agent_id]) : @plage_ouverture.agent
  end

  def set_plage_ouverture
    @plage_ouverture = PlageOuverture.find(params[:id])
  end

  def build_plage_ouverture
    @plage_ouverture = PlageOuverture.new(plage_ouverture_params)
  end

  def plage_ouverture_params
    params.require(:plage_ouverture).permit(:title, :agent_id, :first_day, :start_time, :end_time, :lieu_id, :recurrence, :ignore_benign_errors, motif_ids: [])
  end

  def filter_params
    params.permit(:start, :end, :organisation_id, :agent_id, :page, :current_tab)
  end

  def plage_ouverture_mailer
    Agents::PlageOuvertureMailer.with(plage_ouverture: @plage_ouverture)
  end
end
