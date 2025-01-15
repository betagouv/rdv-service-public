class RdvPlanBlueprint < Blueprinter::Base
  identifier :id

  field :user_id

  association :rdv, blueprint: RdvBlueprint
end
