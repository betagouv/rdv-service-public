class InstanceExport < ApplicationRecord
  belongs_to :agent
  belongs_to :good_job_batch, class_name: "GoodJob::BatchRecord", optional: true
  belongs_to :source_organisation, optional: true, class_name: "Organisation"

  encrypts :api_token
  encrypts :refresh_token

  scope :finished_exports_for_organisation, lambda { |source_organisation_id|
    where(source_organisation_id: source_organisation_id, status: %w[planning_copied motifs_archived])
  }

  validates :status, inclusion: { in: %w[oauth_connected copying_configuration copying_planning planning_copied motifs_archived] }

  def new_instance_organisations
    @new_instance_organisations ||= api_client.get("organisations")["organisations"]
  end

  def create_organisation_on_new_instance!
    new_org_attributes = source_organisation.attributes.slice(*%w[name website phone_number email])
    new_org_attributes.merge!({ external_reference: { external_id: source_organisation.id } })

    destination_org = api_client.post("organisations", new_org_attributes)["organisation"]

    update!(destination_organisation_id: destination_org["id"])
  end

  def source_organisation
    super || agent.organisations.first
  end

  def api_client
    @api_client ||= RdvServicePublicApiClient.new(api_token)
  end

  def copy_to_new_instance!(current_domain)
    transaction do
      update(status: "copying_configuration")
      InstanceExports::CopyConfiguration.new(self).enqueue_batch(current_domain)
    end
  end
end
