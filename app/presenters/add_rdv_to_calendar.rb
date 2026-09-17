class AddRdvToCalendar
  def initialize(rdv, current_user)
    @rdv = rdv
    @current_user = current_user
  end

  delegate :google_url, :outlook_com_url, :office365_url, :ical_url, to: :cal

  private

  def token
    @current_user.participation_for(@rdv).restricted_auth_token
  end

  def cal
    @cal = AddToCalendar::URLs.new(
      start_datetime: @rdv.starts_at,
      end_datetime: @rdv.ends_at,
      timezone: @rdv.organisation.time_zone,
      title: "RDV #{@rdv.motif.name}",
      location: @rdv.ics_location(recipient: @current_user),
      url: Rails.application.routes.url_helpers.rdv_short_from_token_url(token, host: @rdv.domain.host_name),
      description: @rdv.ics_description(@current_user)
    )
  end
end
