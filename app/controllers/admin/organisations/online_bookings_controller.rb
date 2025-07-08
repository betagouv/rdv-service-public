class Admin::Organisations::OnlineBookingsController < AgentAuthController
  before_action :set_organisation

  def show
    authorize(@organisation, policy_class: Agent::OrganisationPolicy)
    set_motifs
  end

  def update
    authorize(@organisation, policy_class: Agent::OrganisationPolicy)

    if @organisation.update(permitted_params)
      flash[:success] = "Configuration mise à jour"
      redirect_to admin_organisation_online_booking_path(@organisation)
    else
      flash[:error] = @organisation.errors.full_messages.to_sentence
      set_motifs
      render :show
    end
  end

  private

  def set_motifs
    @motifs = Agent::MotifPolicy::Scope.apply(current_agent, Motif)
      .available_motifs_for_organisation_and_agent(current_organisation, current_agent)
      .active
      .includes(:organisation)
      .includes(:service)
  end

  def permitted_params
    params.require(:organisation).permit(:online_booking_for_particuliers, :online_booking_for_professionnels)
  end
end
