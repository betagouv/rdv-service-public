RSpec.describe Annotation do
  describe "upsert!" do
    let!(:organisation) { create(:organisation) }
    let!(:territory) { organisation.territory }
    let!(:user) { create(:user, organisations: [organisation]) }

    context "when no annotation already exists for user and territory" do
      it "creates one when upserting content" do
        expect { described_class.upsert!("Lorem ipsum", user:, territory:) }.to change(described_class, :count).by(1)
      end

      it "does nothing when upserting a blank content" do
        expect { described_class.upsert!(" ", user:, territory:) }.not_to change { described_class.where(user:, territory:).count }
      end
    end

    context "when an annotation already exists for user and territory" do
      before do
        described_class.create!(content: "Lorem ipsum", user:, territory:)
      end

      it "updates the existing annotation when upserting content" do
        annotation = described_class.where(user:, territory:).sole
        expect { described_class.upsert!("dolor sit amet", user:, territory:) }.to change { annotation.reload.content }.from("Lorem ipsum").to("dolor sit amet")
      end

      it "deletes the existing annotation when upserting a blank content" do
        expect { described_class.upsert!(" ", user:, territory:) }.to change { described_class.where(user:, territory:).count }.by(-1)
      end
    end
  end
end
