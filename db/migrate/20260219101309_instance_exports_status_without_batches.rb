class InstanceExportsStatusWithoutBatches < ActiveRecord::Migration[8.0]
  def change
    up_only do
      InstanceExport.where(status: "copying_planning").each do |instance_export|
        if instance_export.good_job_batch && instance_export.good_job_batch.jobs.where(finished_at: nil).none?
          instance_export.update(status: "planning_copied")
        end
      end
    end
  end
end
