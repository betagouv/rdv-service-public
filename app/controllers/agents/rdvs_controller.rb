class Agents::RdvsController < AgentAuthController
  before_action :set_rdv, only: %i[show visio create_visio_room]

  def show
    redirect_to admin_organisation_rdv_path(@rdv.organisation, @rdv)
  end

  def visio
    if @rdv.visio_url.present?
      redirect_to @rdv.visio_url, allow_other_host: true
    else
      flash[:error] = "Le lien de visioconférence de ce RDV n'a pas encore été généré"
      redirect_to admin_organisation_rdv_path(@rdv.organisation, @rdv)
    end
  end

  # Une partie de la logique est dupliquée avec app/controllers/admin/rdv_wizard_steps_controller.rb#assign_visio_numerique_room_if_applicable
  # TODO: factoriser dans une prochaine PR
  def create_visio_room
    if !@rdv.motif.visio? || ENV["VISIO_NUMERIQUE_DISABLED"]
      flash[:error] = "Ce RDV n'a pas de visioconférence associée"
    elsif @rdv.visio_url.present?
      # Le lien a déjà été généré (double clic, autre onglet…) : rien à faire
    elsif session[:pro_connect_access_token].blank?
      flash[:error] = "Pour générer le lien de visioconférence, connectez-vous via ProConnect"
    elsif (visio_url = VisioNumerique::CreateRoom.new(access_token: session[:pro_connect_access_token]).visio_url)
      # Mise à jour silencieuse : pas de notification, de webhook ni de synchro d'agenda.
      @rdv.update_columns(visio_url_custom: visio_url, updated_at: Time.zone.now) # rubocop:disable Rails/SkipsModelValidations
      flash[:success] = "Le lien de visioconférence a été généré"
    else
      flash[:error] = "Le lien de visioconférence n'a pas pu être généré, veuillez réessayer"
    end

    redirect_back fallback_location: admin_organisation_rdv_path(@rdv.organisation, @rdv)
  end

  private

  def set_rdv
    @rdv = policy_scope(Rdv, policy_scope_class: Agent::RdvPolicy::Scope).find(params[:id])
    authorize(@rdv, policy_class: Agent::RdvPolicy)
  end

  def pundit_user
    current_agent
  end
end
