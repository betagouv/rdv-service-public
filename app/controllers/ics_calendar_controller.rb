# frozen_string_literal: true

require "icalendar/tzinfo"

# rubocop:disable Rails/ApplicationController
class IcsCalendarController < ActionController::Base
  include RdvsHelper

  before_action :find_agent

  def show
    respond_to do |format|
      format.ics do
        cal = Icalendar::Calendar.new
        cal.x_wr_calname = "#{@agent.full_name} sur #{@agent.domain.name}"

        tz = TZInfo::Timezone.get(Time.zone_default.tzinfo.identifier)
        timezone = tz.ical_timezone(rdvs.last&.starts_at || 1.year.ago)
        cal.add_timezone(timezone)

        add_events(cal)
        cal.publish
        render plain: cal.to_ical
      end
    end
  end

  private

  def find_agent
    @agent = Agent.find_by(calendar_uid: params[:id])

    head :not_found if @agent.nil?
  end

  def rdvs
    @agent.rdvs.order("starts_at desc").limit(500)
  end

  def add_events(cal)
    rdvs.each do |rdv|
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
        event.summary = rdv.collectif? ? rdv_title_in_agenda(rdv) : rdv.motif.name
        event.description = "plus d'infos dans #{@agent.domain.name}: #{admin_organisation_rdv_url(rdv.organisation, rdv.id)}"
      end
    end
  end

  def default_url_options
    super.merge(host: @agent.domain.dns_domain_name)
  end
end
# rubocop:enable Rails/ApplicationController
