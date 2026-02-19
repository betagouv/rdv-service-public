class InstanceExports::PlanningCopiedJob < ApplicationJob
  def perform(batch, _context)
    instance_export = InstanceExport.find(batch.properties[:instance_export_id])
    instance_export.update!(status: "planning_copied")
  end
end
