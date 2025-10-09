class Admin::Organisations::OnlineBookingsController < AgentAuthController
  before_action :set_organisation

  def show
    authorize(@organisation, policy_class: Agent::OrganisationPolicy)
    set_motifs

    @motifs_and_availabilities = @motifs.bookable_by_everyone_or_bookable_by_invited_users.map do |motif|
      {
        motif: motif,
        availabilities_count: available_slots_count(motif),
      }
    end

    @motifs_with_availabilities = @motifs_and_availabilities.select do |motif_with_availabilities|
      motif_with_availabilities[:availabilities_count] > 0
    end

    @motifs_with_missing_availabilities = @motifs_and_availabilities.select do |motif_with_availabilities|
      motif_with_availabilities[:availabilities_count] == 0
    end.pluck(:motif)

    @unavailable_motifs = @motifs.not_bookable_by_everyone_or_not_bookable_by_invited_users

    if @motifs_and_availabilities.empty?
      @online_booking_motifs_form = Admin::OnlineBookingMotifsForm.new([])
      render :new
    end
  end

  def create
    authorize(@organisation, :edit?, policy_class: Agent::OrganisationPolicy)

    motif_ids = params.require(:admin_online_booking_motifs_form).permit(motif_ids: []).fetch(:motif_ids)

    # TODO: ajouter un appel de policy scope
    motifs = current_organisation.motifs.where(id: motif_ids)

    motifs.each do |motif|
      motif.update!(bookable_by: :everyone)
    end

    session[:motifs_opened] = true
    # flash[:success] = "Les motifs #{motifs.pluck(:name).to_sentence} sont ouverts pour la réservation en ligne."
    redirect_to admin_organisation_online_booking_path(current_organisation)
  end

  def edit
    set_motifs
    authorize(@organisation, :edit?, policy_class: Agent::OrganisationPolicy)

    motif_ids = @motifs.bookable_by_everyone_or_bookable_by_invited_users.pluck(:id)
    @online_booking_motifs_form = Admin::OnlineBookingMotifsForm.new(motif_ids)
  end

  def edit_user_type
    authorize(@organisation, :edit?, policy_class: Agent::OrganisationPolicy)
  end

  def update_user_type
    authorize(@organisation, :update?, policy_class: Agent::OrganisationPolicy)

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

  def available_slots_count(motif)
    if motif.collectif?
      motif.rdvs.collectif_and_available_for_reservation.count
    else
      policy_scope(PlageOuverture, policy_scope_class: Agent::PlageOuverturePolicy::Scope).joins(:motifs).where(
        organisation: current_organisation,
        motifs: { id: motif.id }
      ).in_range(Time.zone.now..).count
    end
  end
end
