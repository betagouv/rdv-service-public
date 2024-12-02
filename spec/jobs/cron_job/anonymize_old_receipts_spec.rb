RSpec.describe CronJob::AnonymizeOldReceipts do
  let!(:recent_sms_receipt) do
    travel_to(5.months.ago) { create(:receipt) }
  end
  let!(:old_sms_receipt) do
    travel_to(7.months.ago) { create(:receipt) }
  end

  let!(:old_mail_receipt) do
    travel_to(7.months.ago) { create(:receipt, :mail) }
  end

  it "removes personal information from old receipts" do
    described_class.new.perform

    expect(recent_sms_receipt.reload).to have_attributes(
      content: "Atelier collectif, mardi 20/02 à 16h00. Mairie de Romainville (7 Rue de Paris, Romainville, 93230). Infos et annulation: https://demo.rdv-solidarites.fr/r/asdfasd/ / 0100001111",
      sms_phone_number: "0600001111"
    )

    old_sms_receipt.reload
    expect(old_sms_receipt.content).to match %([valeur unique anonymisée \\d+])
    expect(old_sms_receipt.sms_phone_number).to match %([valeur unique anonymisée \\d+])
    expect(old_sms_receipt.error_message).to be_nil
    expect(old_sms_receipt.sms_count).to eq 2

    old_mail_receipt.reload
    expect(old_mail_receipt.content).to match %([valeur unique anonymisée \\d+])
    expect(old_mail_receipt.error_message).to be_nil
    expect(old_mail_receipt.email_address).to start_with("email_anonymise_")
  end
end
