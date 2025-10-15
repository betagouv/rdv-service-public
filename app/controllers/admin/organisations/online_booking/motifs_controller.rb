class Admin::Organisations::OnlineBooking::MotifsController < AgentAuthController
  before_action :set_organisation
  before_action :set_motif

  def show; end

  def edit; end

  def update
    @motif.assign_attributes(params.require(:motif).permit(:min_public_booking_delay, :max_public_booking_delay, :rdvs_editable_by_user))

    authorize(@motif, policy_class: Agent::MotifPolicy)

    if @motif.save
      flash[:success] = "Les options de réservation en ligne ont été mises à jour."
      redirect_to admin_organisation_online_booking_motif_path(current_organisation, motif_id: @motif.id)
    else
      render :edit
    end
  end

  def open
    if @motif.update(bookable_by: :everyone)
      flash[:success] = "Le motif a été ouvert à la réservation en ligne"
    else
      flash[:error] = @motif.errors.full_messages
    end

    redirect_to admin_organisation_online_booking_motif_path(current_organisation, motif_id: @motif.id)
  end

  def close
    if @motif.update(bookable_by: :agents)
      flash[:success] = "Le motif a été fermé à la réservation en ligne"
    else
      flash[:error] = @motif.errors.full_messages
    end

    redirect_to admin_organisation_online_booking_motif_path(current_organisation, motif_id: @motif.id)
  end

  private

  def set_motif
    @motif = Motif.find(params[:id])
    authorize(@motif, policy_class: Agent::MotifPolicy)
  end

  def pundit_user
    current_agent
  end
end
