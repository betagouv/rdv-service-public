class Admins::SystemMailer < ApplicationMailer
  def rdv_events_stats
    @today_stats = RdvEvent.date_stats(Date.today)
    @yesterday_stats = RdvEvent.date_stats(Date.yesterday)
    mail(to: "contact@rdv-solidarites.fr", subject: "[monitoring] Notifications Stats")
  end
end
