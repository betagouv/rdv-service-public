# frozen_string_literal: true

class LieuBlueprint < Blueprinter::Base
  identifier :id

  fields :name, :address, :single_use?
end
