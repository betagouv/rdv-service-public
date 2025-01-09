class RdvPlanBlueprint < Blueprinter::Base
  identifier :id

  fields :starts_at

  association :motif, blueprint: MotifBlueprint
  association :users, blueprint: UserBlueprint
  association :lieu, blueprint: LieuBlueprint
end
