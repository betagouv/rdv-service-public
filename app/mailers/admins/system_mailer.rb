class Admins::SystemMailer < ApplicationMailer
  def rdv_events_stats
    @today_stats = RdvEvent.date_stats(Time.zone.today)
    @yesterday_stats = RdvEvent.date_stats(Time.zone.today - 1.day)
    title = I18n.t("admins.system_mailer.rdv_events_stats.title", date: I18n.l(Time.zone.today))
    mail(to: "contact@rdv-solidarites.fr", subject: "[monitoring] #{title}")
  end
end
