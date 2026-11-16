# Reconstitue des DeletedRdv à partir des versions PaperTrail "destroy" des RDV supprimés avant
# la mise en place de la table deleted_rdvs.
#
# Usage (depuis une console, une fois le code déployé) :
#   DeletedRdvsBackfill.new(before: <date du déploiement>).call
#
# `before` est obligatoire : les RDV supprimés après le déploiement sont déjà tracés par le callback
# de Rdv, les reprendre créerait des doublons. Le job peut être relancé sans risque : les RDV déjà
# présents (même organisation, même starts_at, même seconde de suppression) sont ignorés.
#
# Limites : les versions de RDV sont purgées après 1 an (CronJob::DestroyOldVersions), on ne peut donc
# pas remonter plus loin. Les RDV de plus de 2 ans sont ignorés, car ils seraient purgés dans la foulée.
class DeletedRdvsBackfill
  BATCH_SIZE = 1000

  def initialize(before:)
    @before = before
  end

  def call
    inserted = 0
    versions.in_batches(of: BATCH_SIZE) do |batch|
      rows = rows_for(batch.to_a)
      next if rows.empty?

      inserted += DeletedRdv.insert_all!(rows).length # rubocop:disable Rails/SkipsModelValidations
    end
    inserted
  end

  private

  def versions
    PaperTrail::Version.where(item_type: "Rdv", event: "destroy").where(created_at: ...@before).where.not(object: nil)
  end

  def rows_for(versions)
    motif_names = Motif.where(id: versions.filter_map { _1.object["motif_id"] }).pluck(:id, :name).to_h
    names = creator_names(versions)
    already_imported = already_imported_keys(versions)
    retention_limit = 2.years.ago

    versions.filter_map do |version|
      rdv = version.object
      next if Time.zone.parse(rdv["starts_at"]) < retention_limit
      next if already_imported.include?(key(rdv["organisation_id"], rdv["starts_at"], version.created_at))

      virtual = version.virtual_attributes || {}
      {
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
        created_at: version.created_at, # date de suppression
        updated_at: version.created_at,
      }
    end
  end

  def creator_names(versions)
    creators = versions.map { [_1.object["created_by_type"], _1.object["created_by_id"]] }.uniq
    { "Agent" => Agent, "User" => User }.flat_map do |type, klass|
      ids = creators.filter_map { |t, id| id if t == type }
      # unscoped : les usagers supprimés (soft delete) sont exclus par le default_scope
      klass.unscoped.where(id: ids).map { |record| [[type, record.id], record.full_name] }
    end.to_h
  end

  def already_imported_keys(versions)
    first, last = versions.map(&:created_at).minmax
    DeletedRdv.where(organisation_id: versions.map { _1.object["organisation_id"] }.uniq, created_at: first..last)
      .pluck(:organisation_id, :starts_at, :created_at)
      .to_set { |organisation_id, starts_at, created_at| key(organisation_id, starts_at, created_at) }
  end

  def key(organisation_id, starts_at, deleted_at)
    [organisation_id, Time.zone.parse(starts_at.to_s).to_i, deleted_at.to_i]
  end
end
