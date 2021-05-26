# frozen_string_literal: true

class Admins::SystemMailerPreview < ActionMailer::Preview
  def rdv_events_stats
    Admins::SystemMailer.rdv_events_stats
  end
end
