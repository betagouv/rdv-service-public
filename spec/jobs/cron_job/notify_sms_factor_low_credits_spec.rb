RSpec.describe CronJob::NotifySmsFactorLowCredits, type: :job do
  context "quand la variable SMS_FACTOR_LIMIT_ALERT n’est pas définie" do
    stub_env_with(SMS_FACTOR_LIMIT_ALERT: nil)

    it "envoie un Sentry pour demander à définir cette variable" do
      expect(Sentry).to receive(:capture_message).with("Merci de définir la variable d’environnement SMS_FACTOR_LIMIT_ALERT")
      described_class.new.perform
    end
  end

  context "quand la variable SMS_FACTOR_LIMIT_ALERT est définie" do
    stub_env_with(SMS_FACTOR_LIMIT_ALERT: "100")

    context "quand la clef SMS_FACTOR_REMAINING_CREDITS n’existe pas" do
      it "ne fait rien" do
        expect(Sentry).not_to receive(:capture_message)
        described_class.new.perform
      end
    end

    context "quand la clef SMS_FACTOR_REMAINING_CREDITS est défini avec une valeur supérieure à SMS_FACTOR_LIMIT_ALERT" do
      before do
        Redis.with_connection do |redis|
          redis.set("SMS_FACTOR_REMAINING_CREDITS", "1000")
        end
      end

      it "ne fait rien" do
        expect(Sentry).not_to receive(:capture_message)
        described_class.new.perform
      end
    end

    context "quand la clef SMS_FACTOR_REMAINING_CREDITS est défini avec une valeur inférieure à SMS_FACTOR_LIMIT_ALERT" do
      before do
        Redis.with_connection do |redis|
          redis.set("SMS_FACTOR_REMAINING_CREDITS", "10")
        end
      end

      it "ne fait rien" do
        expect(Sentry).to receive(:capture_message).with("Les nombres de crédits SMS Factor est inférieur à 100 (actuellement 10).")
        described_class.new.perform
      end
    end
  end
end
