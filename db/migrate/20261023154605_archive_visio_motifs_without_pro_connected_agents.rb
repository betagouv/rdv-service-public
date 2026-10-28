class ArchiveVisioMotifsWithoutProConnectedAgents < ActiveRecord::Migration[8.0]
  WHODUNNIT = "[Migration] ArchiveVisioMotifsWithoutProConnectedAgents".freeze

  def up
    orgas_with_pro_connected_agent = Organisation.joins(:agents).merge(Agent.active).where.not(agents: { pro_connect_openid_sub: nil })

    motifs = Motif.active.visio.where.not(organisation_id: orgas_with_pro_connected_agent.select(:id))

    PaperTrail.request(whodunnit: WHODUNNIT) do
      motifs.find_each do |motif|
        Rails.logger.info "archiving motif #{motif.id} (#{motif.name}) of organisation #{motif.organisation_id}"
        motif.archive
      end
    end
  end

  # Data fix : le down ne réactive pas les motifs, il permet juste de
  # retirer la migration de schema_migrations (ex. pour la rejouer en local sur un dump).
  def down; end
end
