# frozen_string_literal: true

module Outlook
  class DestroyEventJob < ApplicationJob
    queue_as :outlook_sync

    def perform(outlook_id, agent)
      client = Outlook::ApiClient.new(agent)
      client.delete_event!(outlook_id)

      agents_rdv = AgentsRdv.find_by(outlook_id: outlook_id)

      # On utilise #update_columns parce que les validations AR échouent si le rdv est soft-deleted
      # Ça permet aussi d'éviter de lancer les callbacks, dont notamment celui qui amène à l'exécution de ce job
      agents_rdv&.update_columns(outlook_id: nil) # rubocop:disable Rails/SkipsModelValidations
    end
  end
end
