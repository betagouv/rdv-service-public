# frozen_string_literal: true

class Admin::RdvsCollectifsController < AgentAuthController
  respond_to :html
  skip_after_action :verify_authorized, only: :new

  def index
    @rdvs = policy_scope(Rdv).joins(:motif).where(motifs: { collectif: true }).where(organisation: current_organisation)
    @rdvs = @rdvs.order(starts_at: :asc).page(params[:page])
  end

  def new_with_motif
    motif = policy_scope(Motif).find(params[:motif_id])
    @rdv = Rdv.new(organisation: current_organisation, motif: motif, duration_in_min: motif.default_duration_in_min)
    authorize(@rdv, :new?)
  end

  def new
    @motifs = policy_scope(Motif).available_motifs_for_organisation_and_agent(current_organisation, current_agent).where(collectif: true)
  end

  def create
    @rdv = Rdv.new(organisation: current_organisation)
    authorize(@rdv, :new?)

    if @rdv.update(rdv_params)
      redirect_to admin_organisation_rdv_path(current_organisation, @rdv)
    else
      render :new_with_motif
    end
  end

  private

  def rdv_params
    params.require(:rdv).permit(:starts_at, :duration_in_min, :lieu_id, :max_participants_count, :motif_id, agent_ids: [])
  end
end
