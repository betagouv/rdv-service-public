module IcsMultipartAttached
  # Sending icalendar events by email is complicated, buggy and unreliable.
  # This module is added to ApplicationMailer and used in all emails that include an icalendar
  # to make sure we use the same hacks everywhere.

  attr_accessor :ics_payload

  def mail(...)
    return super if ics_payload.blank? || ics_payload_already_added?(message)

    cal = IcalFormatters::Ics.from_payload(ics_payload)

    # Specs
    # iCalendar: https://datatracker.ietf.org/doc/html/rfc5545#section-3.6.1
    #   * See section 3.6.1 for VEVENT
    # iTIP: https://datatracker.ietf.org/doc/html/rfc2446#section-3.2
    #   * See section 3.2 for the semantics of the METHOD
    #
    # See also models/concerns/ical_helpers/ics.rb

    # Previous icalendar-related pull requests in RDV-solidarités
    # https://github.com/betagouv/rdv-solidarites.fr/pull/933
    # https://github.com/betagouv/rdv-solidarites.fr/pull/729

    # Related StackOverflow discussions
    # https://stackoverflow.com/questions/24259827/why-are-my-icalendar-invitations-not-processed-by-the-outlook-sniffer
    # https://stackoverflow.com/questions/19523861/multipart-email-with-text-and-calendar-outlook-doesnt-recognize-ics

    # We try to mimic the behaviour of google calendar emails:
    #
    # 1. We add the icalendar twice to the email:
    #    * once as a `text/calendar` part (with a `method=` in the content type),
    #    * once as an `application/ics` attached .ics file.
    #
    # 2. The method is PUBLISH or CANCEL, not REQUEST: we don’t want replies.
    #
    # 3. the `application/ics` attachment is base64-encoded
    #
    # 4. the `text/calendar` part is base64-encoded, too.
    # This is different from Google: quoted-printable, in ActiveMailer, encodes line breaks as =0D\n,
    # and this seems to break the Outlook automatic integration. #1354

    # The final email parts look like this:
    # - multipart/mixed
    #   - multipart/alternative
    #     - text/plain
    #     - text/html
    #   - text/calendar
    #   - application/ics
    # Google calendar puts the text/calendar inside the multipart/alternative part.
    # We might want to try that too.

    message.attachments[ics_payload[:name]] = {
      mime_type: "application/ics",
      content: Base64.encode64(cal.to_ical),
      encoding: "base64",
    }

    super

    message.add_part(
      Mail::Part.new do
        content_type "text/calendar; method=#{cal.ip_method}; charset=utf-8"
        body Base64.encode64(cal.to_ical)
        content_transfer_encoding "base64"
      end
    )
  end

  private

  def ics_payload_already_added?(message)
    message.parts.any? do |part|
      part.content_type.include?("application/ics") || part.content_type.include?("text/calendar")
    end
  end
end
