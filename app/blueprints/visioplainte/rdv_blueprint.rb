class Visioplainte::RdvBlueprint < Blueprinter::Base
  identifier :id

  fields :starts_at, :created_at, :duration_in_min, :ends_at
end
