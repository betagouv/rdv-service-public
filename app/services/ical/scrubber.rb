class Ical::Scrubber
  SENSITIVE_FIELDS = %w[SUMMARY DESCRIPTION LOCATION LOCATION ORGANIZER ATTENDEE COMMENT CONTACT CREATED-BY].freeze
  SCRUB_REGEXP = /
    ^(?:#{SENSITIVE_FIELDS.join('|')})(?:;[^:]*)?:.*
    (?:\r?\n[ \t].*)*
    \r?\n?
  /ix

  def initialize(raw_ical)
    @raw_ical = raw_ical
  end

  def scrubbed
    @raw_ical.gsub(SCRUB_REGEXP, "")
  end
end
