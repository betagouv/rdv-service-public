class RemoveForeignKeyBetweenInstanceExportsAndGoodJobBatches < ActiveRecord::Migration[8.0]
  def change
    remove_foreign_key :instance_exports, :good_job_batches
  end
end
