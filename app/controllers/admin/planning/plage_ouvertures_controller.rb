class Admin::Planning::PlageOuverturesController < AgentAuthController
  include Admin::Planning::SetAgentsConcern
  respond_to :html, :json

  before_action :set_plage_ouverture, only: %i[show edit update destroy]
  before_action :build_plage_ouverture, only: [:create]
  before_action :set_agents

  def show
    authorize(@plage_ouverture, policy_class: Agent::PlageOuverturePolicy)
  end

  def index
    @multiple_agents_makes_sense = true
    render :multi_agents_index and return if @agents.size > 1

    all_plage_ouvertures = policy_scope(current_organisation.plage_ouvertures, policy_scope_class: Agent::PlageOuverturePolicy::Scope)
      .includes(:lieu, :organisation, :motifs, :agent)
      .where(agent: @agent)
      .order(updated_at: :desc)
    @plage_ouvertures = all_plage_ouvertures
      .where(expired_cached: filter_params[:current_tab] == "expired")
      .page(page_number)
    @plage_ouvertures_before_text_search = @plage_ouvertures

    @plage_ouvertures = @plage_ouvertures.search_by_text(params[:search]) if params[:search].present?
    @display_tabs = all_plage_ouvertures.where(expired_cached: true).any? || params[:current_tab] == "expired"
  end

  def calendar
    # cette page ne charge pas de plages, on setup juste le FullCalendar
    authorize(@agent, :show?, policy_class: Agent::AgentPolicy)
  end

  def new
    if params[:duplicate_plage_ouverture_id].present?
      original_po = PlageOuverture.find(params[:duplicate_plage_ouverture_id])
      defaults = original_po.slice(:title, :lieu_id, :motif_ids, :first_day, :start_time, :end_time, :secondary_start_time, :secondary_end_time, :recurrence)
    else
      defaults = {
        first_day: Time.zone.now,
        start_time: Tod::TimeOfDay.new(9),
        end_time: Tod::TimeOfDay.new(12),
        secondary_start_time: nil,
        secondary_end_time: nil,
      }.merge(params.permit(:first_day, :start_time, :end_time, :motif_ids))
    end
    @plage_ouverture = PlageOuverture.new(
      organisation: current_organisation,
      motif_ids: params[:motif_ids],
      agent: @agent,
      **defaults
    )
    authorize(@plage_ouverture, policy_class: Agent::PlageOuverturePolicy)
    @plage_ouverture.motifs = [@plage_ouverture.available_motifs.sole] if @plage_ouverture.available_motifs.size == 1
  end

  def edit
    authorize(@plage_ouverture, policy_class: Agent::PlageOuverturePolicy)
  end

  def create
    @plage_ouverture.organisation = current_organisation
    authorize(@plage_ouverture, policy_class: Agent::PlageOuverturePolicy)
    if @plage_ouverture.save
      Notifiers::PlageOuvertureCreated.new(@plage_ouverture).perform
      flash[:success] = "Plage d'ouverture créée"
      update_online_booking_banner_display
      redirect_to admin_organisation_planning_plage_ouvertures_path(organisation_id: @plage_ouverture.organisation, agent_id: @plage_ouverture.agent_id)
    else
      render :new
    end
  end

  def update
    authorize(@plage_ouverture, policy_class: Agent::PlageOuverturePolicy)
    if @plage_ouverture.update(plage_ouverture_params)
      Notifiers::PlageOuvertureUpdated.new(@plage_ouverture).perform
      flash[:success] = "La plage d'ouverture a été modifiée."
      update_online_booking_banner_display
      redirect_to admin_organisation_planning_plage_ouvertures_path(organisation_id: @plage_ouverture.organisation, agent_id: @plage_ouverture.agent_id)
    else
      render :edit
    end
  end

  def destroy
    authorize(@plage_ouverture, policy_class: Agent::PlageOuverturePolicy)
    notifier = Notifiers::PlageOuvertureDestroyed.new(@plage_ouverture)
    if @plage_ouverture.destroy
      notifier.perform
      flash[:notice] = "La plage d'ouverture a été supprimée."
      redirect_to admin_organisation_planning_plage_ouvertures_path(@plage_ouverture.organisation, agent_id: @plage_ouverture.agent)
    else
      render :edit
    end
  end

  private

  def update_online_booking_banner_display
    if session["OnlineBookingMotifsForm:completed"]
      banner = OnlineBookingOnboardingBanner.new(current_organisation)
      # S'il n'y a plus besoin de la bannière, on arrête de l'afficher
      unless banner.availabilities_needed?
        session.delete("OnlineBookingMotifsForm:completed")
        flash[:onboarding] = "online_booking_ready"
      end
    end
  end

  def set_plage_ouverture
    @plage_ouverture = PlageOuverture.find(params[:id])
  end

  def build_plage_ouverture
    @plage_ouverture = PlageOuverture.new(plage_ouverture_params)
  end

  def set_agents
    if @plage_ouverture&.agent
      @agent = @plage_ouverture.agent
      @agents = [@agent]
    else
      super
    end
  end

  def plage_ouverture_params
    params.require(:plage_ouverture).permit(
      :title, :agent_id, :first_day, :start_time, :end_time, :secondary_start_time, :secondary_end_time, :lieu_id, :recurrence, :ignore_benign_errors, motif_ids: []
    )
  end

  def filter_params
    params.permit(:start, :end, :organisation_id, :agent_id, :page, :current_tab)
  end

  def plage_ouverture_mailer
    Agents::PlageOuvertureMailer.with(plage_ouverture: @plage_ouverture)
  end
end
