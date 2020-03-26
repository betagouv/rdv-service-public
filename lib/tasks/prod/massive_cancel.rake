# rake "prod:massive_cancel"
# Or with an end_date: rake "prod:massive_cancel[01/10/2021]"
namespace :prod do
  desc "Massive cancel of rdv due to COVID 19"
  task :massive_cancel, [:end_date] => :environment do |_t, args|
    DEFAULT_CANCEL_END_DATE = 15.days.since
    EXCLUDED_DEPARTEMENTS = %w[14 77].freeze
    EXCLUDED_ORGANISATIONS = %w[86].freeze

    args.with_defaults(end_date: DEFAULT_CANCEL_END_DATE)
    rdvs = Rdv.active.status('unknown_future')
              .joins(:organisation).where.not(organisations: { id: EXCLUDED_ORGANISATIONS })
              .where.not(organisations: { departement: EXCLUDED_DEPARTEMENTS })
              .where('DATE(starts_at) < ?', args.end_date.to_date)
    rdvs.each do |rdv|
      rdv.update(status: :excused, cancelled_at: Time.zone.now, notes: "[Annulation COVID-19]" + rdv.notes.to_s)
      rdv.users.map(&:user_to_notify).uniq.each do |user|
        RdvMailer.cancel_rdv_coronavirus(rdv, user).deliver_now if user.email.present?
        TwilioTextMessenger.new(:coronavirus, rdv, user).send_sms if user.formated_phone
      end
    end
    puts "RDV concernés: #{rdvs.size}"
  end
end
