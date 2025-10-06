class LieuBlueprint < Blueprinter::Base
  identifier :id

  fields :name,
         :address,
         :phone_number,
         :organisation_id,
         :latitude,
         :longitude
  field :single_use?, name: :single_use
end
