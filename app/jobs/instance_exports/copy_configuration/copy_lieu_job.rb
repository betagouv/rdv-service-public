class InstanceExports::CopyConfiguration
  class CopyLieuJob < ApplicationJob
    queue_as :latency_5m

    def perform(instance_export_id, lieu_id)
      instance_export = InstanceExport.find(instance_export_id)
      lieu = Lieu.find(lieu_id)
      attributes = lieu.attributes.slice(*%w[name address latitude longitude phone_number availability])

      attributes[:external_reference] = { external_id: lieu.id }
      attributes[:organisation_id] = instance_export.destination_organisation_id

      instance_export.api_client.post("lieux", attributes)
    end
  end
end
