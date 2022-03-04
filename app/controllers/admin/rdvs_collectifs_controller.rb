# frozen_string_literal: true

class Admin::RdvsCollectifsController < AgentAuthController
  respond_to :html

  def index
    @rdvs = policy_scope(Rdv).joins(:motif).where(motifs: { collectif: true }).where(organisation: current_organisation)
    @rdvs = @rdvs.order(starts_at: :asc).page(params[:page])

    @motifs = policy_scope(Motif).available_motifs_for_organisation_and_agent(current_organisation, current_agent).where(collectif: true)

    @form = Admin::RdvCollectifSearchForm.new(params.permit(:motif_id, :organisation_id, :from_date, :with_availabilities))

    @form.from_date ||= Time.zone.now

    if @form.motif_id.present?
      @rdvs = @rdvs.where(motif_id: @form.motif_id)
    end

    if @form.with_availabilities
      @rdvs = @rdvs.includes(:rdvs_users).having("count(rdvs_users.id) < rdvs.max_participants_count")
    end

    @rdvs = @rdvs.where("starts_at >= ?", @form.from_date)
  end

  def new
    motif = policy_scope(Motif).find(params[:motif_id])
    @rdv = Rdv.new(organisation: current_organisation, motif: motif, duration_in_min: motif.default_duration_in_min)
    authorize(@rdv)
  end

  def create
    @rdv = Rdv.new(organisation: current_organisation)
    authorize(@rdv, :new?)

    if @rdv.update(rdv_params)
      flash[:notice] = "#{@rdv.motif.name} créé"
      redirect_to admin_organisation_rdvs_collectifs_path(current_organisation)
    else
      render :new
    end
  end

  def edit
    @rdv = Rdv.find(params[:id])
    authorize(@rdv)
  end

  private

  def rdv_params
    params.require(:rdv).permit(:starts_at, :duration_in_min, :lieu_id, :max_participants_count, :motif_id, agent_ids: [])
  end
end
