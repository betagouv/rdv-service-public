# Trace des RDV supprimés, pour que les agents puissent retrouver ce qui a été supprimé.
# Volontairement sans foreign keys : les données sont conservées même si les références disparaissent.
# Les associations ci-dessous peuvent donc renvoyer nil.
class DeletedRdv < ApplicationRecord
  belongs_to :organisation, optional: true
  belongs_to :motif, optional: true
  belongs_to :lieu, optional: true
  belongs_to :created_by, polymorphic: true, optional: true

  scope :ordered_by_deletion, -> { order(deleted_at: :desc, id: :desc) }

  def self.create_from_rdv!(rdv)
    create!(
      id: rdv.id, # même id que le RDV : voir DeletedRdvsBackfill
      starts_at: rdv.starts_at,
      ends_at: rdv.ends_at,
      organisation_id: rdv.organisation_id,
      motif_id: rdv.motif_id,
      motif_name: rdv.motif&.name,
      lieu_id: rdv.lieu_id,
      status: rdv.status,
      created_by_type: rdv.created_by_type,
      created_by_id: rdv.created_by_id,
      created_by_name: rdv.created_by.try(:full_name),
      user_ids: rdv.participations.map(&:user_id).uniq,
      agent_ids: rdv.agents_rdvs.map(&:agent_id).uniq,
      deleted_at: Time.zone.now
    )
  end

  def users
    User.where(id: user_ids)
  end

  def agents
    Agent.where(id: agent_ids)
  end
end
