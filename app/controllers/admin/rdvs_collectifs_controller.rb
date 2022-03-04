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

    if @form.with_availabilities.to_bool
      @rdvs = @rdvs.where("rdv_collectif_users_count < max_participants_count OR max_participants_count IS NULL")
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

    if @rdv.update(create_rdv_params)
      flash[:notice] = "#{@rdv.motif.name} créé"
      redirect_to admin_organisation_rdvs_collectifs_path(current_organisation)
    else
      render :new
    end
  end

  def edit
    @rdv = Rdv.find(params[:id])

    add_user_ids = params[:add_user]
    users_to_add = User.where(id: add_user_ids)
    users_to_add.ids.each { @rdv.rdvs_users.build(user_id: _1) }

    authorize(@rdv)
  end

  def update
    @rdv = Rdv.find(params[:id])
    authorize(@rdv)

    if @rdv.update(update_rdv_params)
      flash[:notice] = "Participants mis à jour"
      redirect_to admin_organisation_rdvs_collectifs_path(current_organisation)
    else
      render :edit
    end
  end

  private

  def create_rdv_params
    params.require(:rdv).permit(:starts_at, :duration_in_min, :lieu_id, :max_participants_count, :motif_id, agent_ids: [])
  end

  def update_rdv_params
    params.require(:rdv).permit(
      user_ids: [],
      rdvs_users_attributes: %i[user_id send_lifecycle_notifications send_reminder_notification id _destroy]
    )
  end
end
