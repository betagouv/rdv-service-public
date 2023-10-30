class LieuBlueprint < Blueprinter::Base
  identifier :id

  fields :name, :address, :phone_number, :organisation_id
  field :single_use?, name: :single_use
end
