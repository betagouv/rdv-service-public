class MotifBlueprint < Blueprinter::Base
  identifier :id

  fields :name, :location_type, :deleted_at, :bookable_publicly, :service_id, :organisation_id, :collectif,
         :follow_up, :instruction_for_rdv, :bookable_by, :default_duration_in_min,
         :min_public_booking_delay, :max_public_booking_delay
  association :motif_category, blueprint: MotifCategoryBlueprint
end
