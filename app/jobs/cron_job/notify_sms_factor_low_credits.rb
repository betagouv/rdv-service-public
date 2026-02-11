class CronJob::NotifySmsFactorLowCredits < CronJob
  def perform
    limit = 300_000 # 10% des crédits attribués lors du dernier bon de commande
    remaining_credits = Redis.with_connection { _1.get("SMS_FACTOR_REMAINING_CREDITS") }

    if remaining_credits && remaining_credits.to_i < limit.to_i
      Sentry.capture_message("Le crédit SMS Factor est inférieur à #{limit} (actuellement #{remaining_credits}).")
    end
  end
end
