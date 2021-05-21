# frozen_string_literal: true

class AbsenceBlueprint < Blueprinter::Base
  identifier :id

  fields :ical_uid, :title, :first_day, :end_day, :start_time, :end_time
  association :agent, blueprint: AgentBlueprint
  association :organisation, blueprint: OrganisationBlueprint

  field :rrule do |absence|
    Admin::Ics::Absence.rrule(absence)
  end

  field :ical do |absence|
    Admin::Ics::Absence.to_ical(Admin::Ics::Absence.payload(absence))
  end
end
