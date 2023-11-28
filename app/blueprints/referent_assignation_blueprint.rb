class ReferentAssignationBlueprint < Blueprinter::Base
  association :user, blueprint: UserBlueprint
  association :agent, blueprint: AgentBlueprint

  view :without_user do
    exclude :user
  end
end
