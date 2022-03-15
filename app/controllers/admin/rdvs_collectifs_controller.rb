# frozen_string_literal: true

class Admin::RdvsCollectifsController < AgentAuthController
  def index
    @motifs = policy_scope(Motif).available_motifs_for_organisation_and_agent(current_organisation, current_agent).collectif

    @rdvs = policy_scope(Rdv).where(organisation: current_organisation).collectif
    @rdvs = @rdvs.order(starts_at: :asc).page(params[:page])

    @form = Admin::RdvCollectifSearchForm.new(params.permit(:motif_id, :organisation_id, :from_date))

    @rdvs = @form.filter(@rdvs)
  end

  def new
    motif = policy_scope(Motif).find(params[:motif_id])
    @rdv = Rdv.new(organisation: current_organisation, motif: motif, duration_in_min: motif.default_duration_in_min)
    authorize(@rdv)
  end

  def create
    @rdv = Rdv.new(organisation: current_organisation)
    authorize(@rdv, :new?)

    if @rdv.update(create_params)
      flash[:notice] = "#{@rdv.motif.name} créé"
      redirect_to admin_organisation_rdvs_collectifs_path(current_organisation)
    else
      render :new
    end
  end

  private

  def create_params
    params.require(:rdv).permit(:starts_at, :duration_in_min, :lieu_id, :name, :context, :motif_id, agent_ids: [])
  end
end
