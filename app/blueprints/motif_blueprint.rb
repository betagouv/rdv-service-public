# frozen_string_literal: true

class MotifBlueprint < Blueprinter::Base
  identifier :id

  fields :name, :location_type, :deleted_at, :reservable_online, :service_id, :category
end
