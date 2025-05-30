class CronJob::NotifySmsFactorLowCredits < CronJob
  def perform
    Redis.with_connection do |redis|
      limit = ENV.fetch("SMS_FACTOR_LIMIT_ALERT", nil)

      unless limit
        Sentry.capture_message("Merci de définir la variable d’environnement SMS_FACTOR_LIMIT_ALERT")
        break
      end

      remaining_credits = redis.get("SMS_FACTOR_REMAINING_CREDITS")

      break unless remaining_credits

      if remaining_credits.to_i < limit.to_i
        Sentry.capture_message("Les nombres de crédits SMS Factor est inférieur à #{limit} (actuellement #{remaining_credits}).")
      end
    end
  end
end
