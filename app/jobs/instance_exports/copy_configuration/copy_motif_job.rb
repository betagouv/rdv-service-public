class InstanceExports::CopyConfiguration
  class CopyMotifJob < ApplicationJob
    queue_as :latency_5m

    MOTIF_ATTRIBUTE_NAMES = %i[
      name
      color
      default_duration_in_min
      min_public_booking_delay
      max_public_booking_delay
      restriction_for_rdv
      instruction_for_rdv
      for_secretariat
      follow_up
      visibility_type
      custom_cancel_warning_message
      collectif
      location_type
      rdvs_editable_by_user
      rdvs_cancellable_by_user
      bookable_by
      deleted_at
    ].freeze

    def perform(instance_export_id, motif_id)
      instance_export = InstanceExport.find(instance_export_id)
      motif = Motif.find(motif_id)
      attributes = motif.attributes.symbolize_keys.slice(*MOTIF_ATTRIBUTE_NAMES)

      attributes[:external_reference] = { external_id: motif.id }
      attributes[:organisation_id] = instance_export.destination_organisation_id

      instance_export.api_client.post("motifs", attributes)
    end
  end
end
