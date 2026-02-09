class CreateRdvInNewInstance
  def initialize(params:, controller:, oauth_application:)
    @params = params
    @controller = controller
    @oauth_application = oauth_application
  end

  def create!
    rdv = build_rdv

    controller.send(:authorize, rdv, :update?, policy_class: Agent::RdvPolicy)

    Rdv.transaction do
      save_rdv_and_participations!(rdv)
      create_external_reference!(rdv)
    end

    rdv
  end

  private

  def build_rdv
    # On crée le rendez-vous via ActiveRecord sans lancer les Notifiers, ce qui évite de déclencher des callbacks de notifications pour les agents et les usager
    rdv = Rdv.new(
      params.permit(%w[starts_at status cancelled_at context ends_at name max_participants_count])
    )

    if rdv.starts_at > Time.zone.now
      raise "Cet endpoint ne doit pas être utilisé pour créer des rendez-vous à venir"
    end

    rdv.lieu_id = ExternalReference.find_by(item_type: "Lieu", external_id: params[:lieu_external_id], oauth_application:)&.item_id
    rdv.motif_id = ExternalReference.find_by(item_type: "Motif", external_id: params[:motif_external_id], oauth_application:)&.item_id
    rdv.organisation_id = rdv.motif.organisation_id

    rdv.agents = Agent.where(email: params[:agent_emails])

    rdv.created_by = if params[:created_by_type] == "User"
                       # On peut uniquement utiliser cette logique pour les users parce qu'on n'a pas d'external_ids sur les agents ou les prescripteurs
                       ExternalReference.find_by(item_type: params[:created_by_type], external_id: params[:created_by_external_id], oauth_application:)&.item
                     else
                       # Il faut un created_by sur le rendez-vous pour initialiser les created_by des participations
                       # Mais le champs n'est pas utilisé à part pour envoyer des notifications (ce qu'on ne fait pas ici)
                       # ou identifier un prescripteur, ce qui n'est pas très utile pour les rendez-vous passés.
                       # On peut donc se permettre de faire l'approximation que c'est l'agent du rendez-vous qui l'a créé.
                       #
                       #
                       # Ça permet d'éviter d'avoir à copier les informations des prescripteurs (pour le moment).
                       rdv.agents.first
                     end

    rdv
  end

  def save_rdv_and_participations!(rdv)
    if rdv.collectif?
      rdv.save!

      params[:participations].each do |participation_params|
        Participation.create(
          rdv: rdv,
          user_id: ExternalReference.find_by(item_type: "User", external_id: participation_params[:user_external_id], oauth_application:)&.item_id,
          status: participation_params[:status],
          created_by: rdv.created_by
        )
      end
    else
      user_external_ids = params[:participations].pluck(:user_external_id)
      rdv.user_ids = ExternalReference.where(item_type: "User", external_id: user_external_ids, oauth_application:).map(&:item_id)
      rdv.save!
    end
  end

  def create_external_reference!(rdv)
    if params[:external_reference].present?
      ExternalReference.create!(
        params.require(:external_reference).permit(:external_id, :external_url).merge(
          item: rdv,
          oauth_application:
        )
      )
    end
  end

  attr_reader :params, :controller, :oauth_application
end
