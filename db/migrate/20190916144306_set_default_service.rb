class SetDefaultService < ActiveRecord::Migration[6.0]
  def change
    Service.create!(name: "Protection Maternelle Infantile", organisation_id: Organisation.first.id)
    Service.create!(name: "Service Social", organisation_id: Organisation.first.id)
    Pro.update_all(service_id: Service.first.id)
    Motif.update_all(service_id: Service.first.id)
  end
end
