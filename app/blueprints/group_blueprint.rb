# frozen_string_literal: true

class GroupBlueprint < Blueprinter::Base
  identifier :id

  field :departement_number, name: :name
  field :name, name: :label
end
