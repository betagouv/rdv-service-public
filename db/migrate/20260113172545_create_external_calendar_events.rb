class CreateExternalCalendarEvents < ActiveRecord::Migration[8.0]
  def up
    create_table :external_calendar_events do |t| # rubocop:disable Rails/CreateTableWithTimestamps
      t.references :agent, null: false, index: true, foreign_key: true
      t.datetime :starts_at, null: false
      t.datetime :ends_at, null: false
      t.string :url, null: false
    end

    caldav_absences = Absence.where.not(caldav_url: nil)
    caldav_absences.find_each do |caldav_absence|
      ExternalCalendarEvent.create!(
        agent: caldav_absence.agent,
        url: caldav_absence.caldav_url,
        starts_at: caldav_absence.starts_at,
        ends_at: caldav_absence.ends_at
      )
    end
    caldav_absences.delete_all
  end

  def down
    ExternalCalendarEvent.find_each do |external_event|
      Absence.create!(
        agent: external_event.agent,
        caldav_url: external_event.url,
        first_day: external_event.starts_at.to_date,
        end_day: external_event.ends_at.to_date,
        start_time: Tod::TimeOfDay(external_event.starts_at),
        end_time: Tod::TimeOfDay(external_event.ends_at),
        title: "Indisponibilité provenant d’un agenda externe"
      )
    end

    drop_table :external_calendar_events
  end
end
