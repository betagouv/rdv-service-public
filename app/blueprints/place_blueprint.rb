# frozen_string_literal: true

class PlaceBlueprint < Blueprinter::Base
  identifier :id

  field :name, name: :label
  field :organisation_id, name: :organization_id
  fields :address, :latitude, :longitude, :phone_number
end
