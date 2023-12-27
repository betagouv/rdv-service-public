# # Code de migration de YAML à JSON, à lancer une fois cette migration passée en prod.
# # Inspiré de la doc officielle : https://github.com/paper-trail-gem/paper_trail/blob/v12.3.0/README.md#convert-existing-yaml-data-to-json
#
# ::ActiveRecord.use_yaml_unsafe_load = true
# permitted_classes = [Time, Date, ActiveRecord::Type::Time::Value]
#
# not_migrated_versions = PaperTrail::Version.where.not(old_object: nil).or(PaperTrail::Version.where.not(old_object_changes: nil))
#
# not_migrated_versions.find_in_batches(batch_size: 10000) do |batch|
#   update_hash = batch.map do |version|
#     {
#       id: version.id,
#       item_type: version.item_type,
#       item_id: version.item_id,
#       event: version.event,
#       object: YAML.safe_load(version.old_object || "", permitted_classes: permitted_classes, aliases: true),
#       object_changes: YAML.safe_load(version.old_object_changes || "", permitted_classes: permitted_classes, aliases: true),
#       old_object: nil,
#       old_object_changes: nil,
#     }
#   end
#
#   break if update_hash.empty?
#
#   PaperTrail::Version.upsert_all(update_hash, update_only: %i[object object_changes old_object old_object_changes], record_timestamps: false)
# end
#
class ConvertPaperTrailToJson < ActiveRecord::Migration[7.0]
  def change
    safety_assured do
      rename_column :versions, :object, :old_object
      add_column :versions, :object, :jsonb

      rename_column :versions, :object_changes, :old_object_changes
      add_column :versions, :object_changes, :jsonb
    end
  end
end
