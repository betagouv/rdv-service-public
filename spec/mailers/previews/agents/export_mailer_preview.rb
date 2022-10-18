# frozen_string_literal: true

class Agents::ExportMailerPreview < ActionMailer::Preview
  def rdv_export
    agent = Agent.first
    options = {
      start: Time.zone.today - 4.years - 7.days,
      end: Time.zone.today - 4.years,
    }
    Agents::ExportMailer.rdv_export(agent, agent.organisations.first, options)
  end

  def rdvs_users_export
    agent = Agent.first
    territory = Territory.first
    Agents::ExportMailer.rdvs_users_export(agent, territory)
  end
end
