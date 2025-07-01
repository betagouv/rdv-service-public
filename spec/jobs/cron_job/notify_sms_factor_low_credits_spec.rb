RSpec.describe CronJob::NotifySmsFactorLowCredits, type: :job do
  context "quand la clef SMS_FACTOR_REMAINING_CREDITS n’existe pas" do
    it "ne fait rien" do
      expect(Sentry).not_to receive(:capture_message)
      described_class.new.perform
    end
  end

  context "quand la clef SMS_FACTOR_REMAINING_CREDITS est définie avec une valeur supérieure à la limite" do
    before do
      Redis.with_connection do |redis|
        redis.set("SMS_FACTOR_REMAINING_CREDITS", "400000")
      end
    end

    it "ne fait rien" do
      expect(Sentry).not_to receive(:capture_message)
      described_class.new.perform
    end
  end

  context "quand la clef SMS_FACTOR_REMAINING_CREDITS est défini avec une valeur inférieure à la limite" do
    before do
      Redis.with_connection do |redis|
        redis.set("SMS_FACTOR_REMAINING_CREDITS", "10")
      end
    end

    it "envoie un message d’alerte Sentry" do
      expect(Sentry).to receive(:capture_message).with("Le crédit SMS Factor est inférieur à 300000 (actuellement 10).")
      described_class.new.perform
    end
  end
end
