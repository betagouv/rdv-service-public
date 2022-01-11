# frozen_string_literal: true

class Agents::ExportMailerPreview < ActionMailer::Preview
  def rdv_export
    agent = Agent.first
    options = {
      start: Date.today.in_time_zone - 4.years - 7.days,
      end: Date.today.in_time_zone - 4.years
    }
    Agents::ExportMailer.rdv_export(agent.id, agent.organisations.first.id, options)
  end
end
