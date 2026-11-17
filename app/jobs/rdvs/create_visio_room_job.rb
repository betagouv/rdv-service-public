module Rdvs
  # Crée le salon Visio (visio.numerique.gouv.fr) d'un RDV qui vient d'être créé,
  # avec le jeton Menshen d'un des agents du RDV.
  class CreateVisioRoomJob < ApplicationJob
    def perform(rdv_id:)
      rdv = Rdv.find_by(id: rdv_id)
      return if rdv.nil?
      return unless rdv.visio_room_creation_needed?

      agent = rdv.agents.with_valid_menshen_access_token.order(:id).first
      visio_url = VisioNumerique::CreateRoom.new(agent:).visio_url
      return if visio_url.nil?

      # Mise à jour silencieuse : pas de notification, de webhook ni de synchro d'agenda.
      # Les liens envoyés pointent vers une URL stable qui redirige vers le salon.
      rdv.update_columns(visio_url_custom: visio_url, updated_at: Time.zone.now) # rubocop:disable Rails/SkipsModelValidations
    end
  end
end
