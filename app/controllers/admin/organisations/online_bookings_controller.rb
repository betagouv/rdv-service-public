class Admin::Organisations::OnlineBookingsController < AgentAuthController
  before_action :set_organisation

  def show
    authorize(@organisation, policy_class: Agent::OrganisationPolicy)
    set_motifs

    if @motifs.bookable_by_everyone.none?
      @online_booking_motifs_form = Admin::OnlineBookingMotifsForm.new(current_organisation)

      @cancel_path = admin_organisation_configuration_path(current_organisation)
      render :form
    else
      @open_motifs = @motifs.bookable_by_everyone
      @closed_motifs = @motifs.where.not(bookable_by: :everyone)

      @banner = OnlineBookingOnboardingBanner.new(current_organisation)
    end
  end

  def edit
    authorize(@organisation, :edit?, policy_class: Agent::OrganisationPolicy)
    set_motifs

    @online_booking_motifs_form = Admin::OnlineBookingMotifsForm.new(current_organisation)

    @cancel_path = admin_organisation_online_booking_path(current_organisation)
    render :form
  end

  def update
    authorize(@organisation, :edit?, policy_class: Agent::OrganisationPolicy)
    set_motifs

    form = Admin::OnlineBookingMotifsForm.new(current_organisation)

    form.submit(params.dig(:admin_online_booking_motifs_form, :motif_ids), flash)

    redirect_to admin_organisation_online_booking_path(current_organisation)
  end

  def edit_user_type
    authorize(@organisation, :edit?, policy_class: Agent::OrganisationPolicy)
  end

  def update_user_type
    authorize(@organisation, :update?, policy_class: Agent::OrganisationPolicy)

    if @organisation.update(permitted_params)
      flash[:success] = "Profil des usagers mis à jour"
      redirect_to admin_organisation_online_booking_path(@organisation)
    else
      flash[:error] = @organisation.errors.full_messages.to_sentence
      render :edit_user_type
    end
  end

  private

  def pundit_user
    current_agent
  end

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
