# Reconstitue des DeletedRdv à partir des versions PaperTrail "destroy" des RDV supprimés avant
# la mise en place de la table deleted_rdvs.
#
# Usage (depuis une console, une fois le code déployé) :
#   DeletedRdvsBackfill.new.call
#
# Un DeletedRdv a le même id que le RDV supprimé, donc le backfill peut être rejoué à volonté et ne
# touche pas aux RDV déjà tracés par le callback de Rdv (INSERT ... ON CONFLICT DO NOTHING). On évite
# volontairement l'upsert : il écraserait des lignes écrites au moment de la suppression, complètes,
# par des données reconstituées après coup (motif_name ou created_by_name pourraient devenir nil).
#
# Limites : les versions de RDV sont purgées après 1 an (CronJob::DestroyOldVersions), on ne peut donc
# pas remonter plus loin. Les RDV de plus de 2 ans sont ignorés, car ils seraient purgés dans la foulée.
class DeletedRdvsBackfill
  BATCH_SIZE = 1000

  # Retourne le nombre de lignes créées
  def call
    inserted = 0
    versions.in_batches(of: BATCH_SIZE) do |batch|
      rows = rows_for(batch.to_a)
      next if rows.empty?

      inserted += DeletedRdv.insert_all(rows, unique_by: :id).length # rubocop:disable Rails/SkipsModelValidations
    end
    inserted
  end

  private

  def versions
    PaperTrail::Version.where(item_type: "Rdv", event: "destroy").where.not(object: nil)
  end

  def rows_for(versions)
    motif_names = Motif.where(id: versions.filter_map { _1.object["motif_id"] }).pluck(:id, :name).to_h
    names = creator_names(versions)
    deleter_ids = deleter_agent_ids(versions)
    retention_limit = 2.years.ago

    versions.filter_map do |version|
      rdv = version.object
      next if Time.zone.parse(rdv["starts_at"]) < retention_limit

      virtual = version.virtual_attributes || {}
      {
        id: version.item_id,
        starts_at: rdv["starts_at"],
        ends_at: rdv["ends_at"],
        organisation_id: rdv["organisation_id"],
        motif_id: rdv["motif_id"],
        motif_name: motif_names[rdv["motif_id"]],
        lieu_id: rdv["lieu_id"],
        status: rdv["status"],
        created_by_type: rdv["created_by_type"],
        created_by_id: rdv["created_by_id"],
        created_by_name: names[[rdv["created_by_type"], rdv["created_by_id"]]],
        user_ids: Array(virtual["user_ids"]).uniq,
        agent_ids: Array(virtual["agent_ids"]).uniq,
        deleted_by_agent_id: deleter_ids[version.item_id],
        deleted_at: version.created_at,
      }
    end
  end

  # whodunnit ressemble à "[Agent] MARIE CLAIN (id=25901)" ; il est vidé après 1 an (RGPD)
  # whodunnit ressemble à "[Agent] MARIE CLAIN (id=25901)" ; il est vidé après 1 an (RGPD).
  # On ne garde l'id que si l'agent appartient (ou appartenait encore) à l'organisation du RDV,
  # pour ne pas rattacher une suppression à un agent qui n'a rien à voir.
  # Retourne { id de la version du RDV => agent_id }
  def deleter_agent_ids(versions)
    candidates = versions.to_h do |version|
      [version.item_id, [version.object["organisation_id"], version.whodunnit.to_s[/\A\[Agent\] .*\(id=(\d+)\)\z/, 1]&.to_i]]
    end
    members = AgentRole.where(agent_id: candidates.values.filter_map(&:last)).pluck(:organisation_id, :agent_id).to_set
    candidates.filter_map { |rdv_id, (organisation_id, agent_id)| [rdv_id, agent_id] if members.include?([organisation_id, agent_id]) }.to_h
  end

  def creator_names(versions)
    creators = versions.map { [_1.object["created_by_type"], _1.object["created_by_id"]] }.uniq
    { "Agent" => Agent, "User" => User }.flat_map do |type, klass|
      ids = creators.filter_map { |t, id| id if t == type }
      # unscoped : les usagers supprimés (soft delete) sont exclus par le default_scope
      klass.unscoped.where(id: ids).map { |record| [[type, record.id], record.full_name] }
    end.to_h
  end
end
