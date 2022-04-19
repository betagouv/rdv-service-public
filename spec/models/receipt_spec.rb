# frozen_string_literal: true

describe Receipt, type: :model do
  describe "scopes" do
    describe "old" do
      it do
        old_receipt = travel_to(3.months.ago) { create :receipt, rdv: create(:rdv, starts_at: Time.zone.now) }
        recent_receipt = create :receipt, rdv: create(:rdv, starts_at: 1.day.ago)
        future_receipt = create :receipt, rdv: create(:rdv, starts_at: 4.months.from_now)

        old_receipts = described_class.old

        expect(old_receipts).to include old_receipt
        expect(old_receipts).not_to include recent_receipt, future_receipt
      end
    end
  end
end
