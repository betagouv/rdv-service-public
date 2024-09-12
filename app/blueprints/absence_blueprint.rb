class AbsenceBlueprint < Blueprinter::Base
  identifier :id

  fields :ical_uid, :title, :first_day, :end_day, :start_time, :end_time
  association :agent, blueprint: AgentBlueprint

  # TODO: Supprimer quand la solution à ce problème est mise en place:
  #   https://github.com/betagouv/rdv-solidarites.fr/pull/3456
  field(:organisation) do |absence|
    organisation = absence.agent.organisations.first
    OrganisationBlueprint.render_as_hash(organisation) if organisation
  end

  # rubocop:disable Style/SymbolProc
  field(:rrule) { _1.rrule }
  field(:ical) do |absence|
    IcalHelpers::Ics.from_payload(absence.payload).to_ical
  end
  # rubocop:enable Style/SymbolProc
end
