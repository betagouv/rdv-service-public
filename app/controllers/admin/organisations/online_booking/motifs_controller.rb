class Admin::Organisations::OnlineBooking::MotifsController < AgentAuthController
  before_action :set_organisation
  before_action :set_motif
  before_action { @current_menu_item = :menu_online_booking }

  def show; end

  def edit; end

  def update
    @motif.assign_attributes(params.require(:motif).permit(:min_public_booking_delay, :max_public_booking_delay, :rdvs_editable_by_user))

    # On fait un deuxième authorize pour s'assurer que les permissions sont encore valides sur la nouvelle version du motif.
    # C'est pas strictement nécessaire ici vu qu'on ne change pas d'association, mais on le met quand même au cas où des changements de permissions soient ajoutés plus tard.
    authorize(@motif, policy_class: Agent::MotifPolicy)

    if @motif.save
      flash[:success] = "Les options de réservation en ligne ont été mises à jour."
      redirect_to admin_organisation_online_booking_motif_path(current_organisation, motif_id: @motif.id)
    else
      render :edit
    end
  end

  def edit_instructions; end

  def update_instructions
    @motif.assign_attributes(params.require(:motif).permit(:restriction_for_rdv, :instruction_for_rdv))

    if @motif.save
      flash[:success] = "Les consignes pour les usagers ont été mises à jour."
      redirect_to admin_organisation_online_booking_motif_path(current_organisation, motif_id: @motif.id)
    else
      render :edit_instructions
    end
  end

  def edit_sectorisation; end

  def update_sectorisation
    @motif.assign_attributes(params.require(:motif).permit(:sectorisation_level))

    if @motif.save
      flash[:success] = "Le niveau de sectorisation a été mis à jour."
      redirect_to admin_organisation_online_booking_motif_path(current_organisation, motif_id: @motif.id)
    else
      render :edit_sectorisation
    end
  end

  def update_bookable_by
    if @motif.update(params.permit(:bookable_by))

      success_messages = {
        everyone: "Le motif a été ouvert à la réservation en ligne",
        agents: "Le motif a été fermé à la réservation en ligne",
        agents_and_prescripteurs_and_invited_users: "La réservation en ligne pour ce motif est maintenant ouverte uniquement aux usagers invités",
      }

      flash[:success] = success_messages.fetch(@motif.bookable_by.to_sym)
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
