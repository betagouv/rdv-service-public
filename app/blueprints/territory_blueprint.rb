class TerritoryBlueprint < Blueprinter::Base
  identifier :id

  fields :departement_number, :name

  association :motif_categories, blueprint: MotifCategoryBlueprint
end
