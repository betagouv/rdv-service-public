# rake "prod:massive_cancel"
# Or with an end_date: rake "prod:massive_cancel[01/10/2021]"
namespace :prod do
  desc "Massive cancel of rdv due to COVID 19"
  task :massive_cancel, [:end_date] => :environment do |_t, args|
    args.with_defaults(end_date: 15.days.since)
    rdvs = Rdv.active.status('unknown_future').joins(:organisation).where("departement != '14'").where('DATE(starts_at) < ?', args.end_date.to_date)
    puts "RDV concernés: #{rdvs.size}"
    now = Time.now
    rdvs.each do |rdv|
      rdv.update(status: :excused, cancelled_at: now, notes: "[Annulation COVID-19]" + rdv.notes.to_s)
      rdv.users.map(&:user_to_notify).uniq.each do |user|
        RdvMailer.cancel_rdv_coronavirus(rdv, user).deliver_now if user.email.present?
        TwilioTextMessenger.new(:coronavirus, rdv, user).send_sms if user.formated_phone
      end
    end
  end
end
