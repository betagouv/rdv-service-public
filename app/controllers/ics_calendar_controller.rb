# frozen_string_literal: true

# rubocop:disable Rails/ApplicationController
class IcsCalendarController < ActionController::Base
  def show
    @agent = Agent.find_by(calendar_uid: params[:id])

    if @agent.nil?
      return head :not_found
    end

    respond_to do |format|
      format.ics do
        cal = Icalendar::Calendar.new
        cal.x_wr_calname = "#{@agent.full_name} sur RDV Solidarités"
        add_events(cal)
        cal.publish
        render plain: cal.to_ical
      end
    end
  end

  private

  def add_events(cal)
    @agent.rdvs.order("starts_at desc").limit(500).each do |rdv|
      cal.event do |event|
        dtstart = Icalendar::Values::DateTime.new(
          rdv.starts_at,
          "tzid" => Time.zone_default.tzinfo.identifier
        )
        event.dtstart = dtstart

        dtend = Icalendar::Values::DateTime.new(
          rdv.ends_at,
          "tzid" => Time.zone_default.tzinfo.identifier
        )
        event.dtend = dtend

        event.location = rdv.address_without_personal_information
        event.status = rdv.cancelled? ? "CANCELLED" : "CONFIRMED"

        event.uid = rdv.uuid
        event.summary = "RDV via RDV Solidarités"
        event.description = "plus d'infos dans RDV Solidarités: #{admin_organisation_rdv_url(rdv.organisation, rdv.id)}"
      end
    end
  end
end
# rubocop:enable Rails/ApplicationController
