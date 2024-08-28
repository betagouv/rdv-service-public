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

    expect(old_sms_receipt.reload).to have_attributes(
      content: "[valeur anonymisée]",
      sms_phone_number: "[valeur anonymisée]",
      error_message: nil, # expected to be nil because it was blank before anonymization
      sms_count: 2
    )

    expect(old_mail_receipt.reload).to have_attributes(
      content: "[valeur anonymisée]",
      error_message: nil
    )
    expect(old_mail_receipt.email_address).to start_with("email_anonymise_")
  end
end
