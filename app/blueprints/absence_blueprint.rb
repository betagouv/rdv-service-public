class AbsenceBlueprint < Blueprinter::Base
  identifier :id

  fields :title, :first_day, :start_time, :end_time
  association :agent, blueprint: AgentBlueprint
  association :organisation, blueprint: OrganisationBlueprint
end
