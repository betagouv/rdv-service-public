# frozen_string_literal: true

class MotifCategoryBlueprint < Blueprinter::Base
  identifier :id

  fields :name, :short_name
end
