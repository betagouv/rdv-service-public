class Admin::PreferencesForm
  include BenignErrors
  include ActiveModel::Model

  attr_reader :agent

  delegate(
    :rdv_notifications_level,
    :rdv_notifications_level_changed?,
    :plage_ouverture_notification_level,
    :absence_notification_level,
    :errors,
    to: :agent
  )

  validate :warn_ics_sync

  def initialize(agent:)
    @agent = agent
  end

  def submit(params)
    params_form = params.dup.to_h.symbolize_keys
    params_agent = params_form.slice!(:ignore_benign_errors)

    assign_attributes(params_form)
    agent.assign_attributes(params_agent)
    return unless valid?

    agent.save
  end

  def warn_ics_sync
    return if ignore_benign_errors || !rdv_notifications_level_changed? || rdv_notifications_level == "all"

    add_benign_error(
      <<~TXT
        Si vous avez un calendrier externe (par exemple Outlook) synchronisé avec RDV Solidarités
        via email, nous vous conseillons de recevoir un email de notification pour chaque changement
        pour éviter de rater des synchronisations.
      TXT
    )
  end
end
