class MotifBlueprint < Blueprinter::Base
  identifier :id

  fields :name, :location_type, :deleted_at, :bookable_publicly, :service_id, :collectif, :follow_up, :instruction_for_rdv, :bookable_by
  association :motif_category, blueprint: MotifCategoryBlueprint
end
