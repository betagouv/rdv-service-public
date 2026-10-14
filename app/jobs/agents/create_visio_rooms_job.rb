module Agents
  # Crée des salons Visio (visio.numerique.gouv.fr) pour les RDV à venir en visio des organisations de l'agent
  # qui n'en ont pas encore, en profitant du jeton ProConnect obtenu à sa connexion.
  # Les salons sont ouverts : peu importe quel agent de l'organisation les crée.
  class CreateVisioRoomsJob < ApplicationJob
    # Le jeton d'accès ProConnect ne doit pas apparaître dans Sentry
    self.log_arguments = false

    def perform(agent, pro_connect_access_token)
      return if ENV["VISIO_NUMERIQUE_DISABLED"]
      return if pro_connect_access_token.blank?

      rdvs_without_visio_room(agent).find_each do |rdv|
        visio_url = VisioNumerique::CreateRoom.new(access_token: pro_connect_access_token).visio_url
        break if visio_url.nil? # jeton expiré ou API indisponible : inutile d'insister

        # Mise à jour silencieuse : pas de notification, de webhook ni de synchro d'agenda.
        # Les liens déjà envoyés pointent vers une URL stable qui redirige vers la nouvelle salle.
        rdv.update_columns(visio_url_custom: visio_url, updated_at: Time.zone.now) # rubocop:disable Rails/SkipsModelValidations
      end
    end

    private

    def rdvs_without_visio_room(agent)
      Rdv.where(organisation: agent.organisations)
        .joins(:motif).merge(Motif.visio)
        .future
        .not_cancelled
        .where(visio_url_custom: [nil, ""])
    end
  end
end
