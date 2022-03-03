# frozen_string_literal: true

class Admin::RdvsCollectifsController < AgentAuthController
  respond_to :html

  def index
    @rdvs = policy_scope(Rdv).joins(:motif).where(motifs: { collectif: true }).where(organisation: current_organisation)
    @rdvs = @rdvs.order(starts_at: :asc).page(params[:page])
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
