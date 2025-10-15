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
      render :edit_online_booking
    end
  end

  def open; end

  def close; end

  private

  def set_motif
    @motif = Motif.find(params[:id])
    authorize(@motif, policy_class: Agent::MotifPolicy)
  end

  def pundit_user
    current_agent
  end
end
