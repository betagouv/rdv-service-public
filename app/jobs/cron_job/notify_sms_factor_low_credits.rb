class CronJob::NotifySmsFactorLowCredits < CronJob
  def perform
    Redis.with_connection do |redis|
      limit = 300_000 # 10% des crédits attribués lors du dernier bon de commande

      remaining_credits = redis.get("SMS_FACTOR_REMAINING_CREDITS")

      break unless remaining_credits

      if remaining_credits.to_i < limit.to_i
        Sentry.capture_message("Le crédit SMS Factor est inférieur à #{limit} (actuellement #{remaining_credits}).")
      end
    end
  end
end
