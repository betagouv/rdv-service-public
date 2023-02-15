# frozen_string_literal: true

class MotifBlueprint < Blueprinter::Base
  identifier :id

  fields :name, :location_type, :deleted_at, :bookable_publicly, :service_id, :organisation_id, :collectif, :follow_up
  association :motif_category, blueprint: MotifCategoryBlueprint
end
