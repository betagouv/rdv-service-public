class RemoveSecretariatService < ActiveRecord::Migration[8.0]
  WHODUNNIT = "[Migration] RemoveSecretariatService".freeze

  def up
    service = Service.find_by(name: "Secrétariat")
    return if service.nil?

    PaperTrail.request(whodunnit: WHODUNNIT) do
      AgentService.where(service:).destroy_all
      TerritoryService.where(service:).destroy_all

      # Les motifs actifs ne peuvent pas être rattachés au secrétariat (cf. Motif#not_associated_with_secretariat),
      # seuls des motifs supprimés peuvent encore y faire référence.
      # S'il reste un motif actif, la clé étrangère fera échouer la suppression du service.
      Motif.where(service:).where.not(deleted_at: nil).update_all(service_id: nil)

      service.destroy!
    end
  end

  # Data fix : le down ne restaure pas le service, il permet juste de
  # retirer la migration de schema_migrations (ex. pour la rejouer en local sur un dump).
  def down; end
end
