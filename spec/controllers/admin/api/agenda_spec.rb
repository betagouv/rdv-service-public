# rubocop:disable RSpec/PredicateMatcher
RSpec.describe Admin::Api::Agenda do
  describe "#realtime_refresh?" do
    context "when agent has enabled the flag" do
      let(:agent) { build(:agent, feature_flags: { new_planning: true }) }

      it "returns true only if REALTIME_AGENDA_FOR_BETA_TESTERS is set to true" do
        expect(described_class.realtime_refresh?(agent)).to be_falsey

        with_modified_env(REALTIME_AGENDA_FOR_BETA_TESTERS: "false") do
          expect(described_class.realtime_refresh?(agent)).to be_falsey
        end

        with_modified_env(REALTIME_AGENDA_FOR_BETA_TESTERS: "true") do
          expect(described_class.realtime_refresh?(agent)).to be_truthy
        end
      end
    end

    context "when agent has NOT enabled the flag" do
      let(:agent) { build(:agent, feature_flags: { new_planning: false }) }

      it "returns true only if REALTIME_AGENDA_FOR_NON_BETA_TESTERS is set to true" do
        expect(described_class.realtime_refresh?(agent)).to be_falsey

        with_modified_env(REALTIME_AGENDA_FOR_NON_BETA_TESTERS: "false") do
          expect(described_class.realtime_refresh?(agent)).to be_falsey
        end

        with_modified_env(REALTIME_AGENDA_FOR_NON_BETA_TESTERS: "true") do
          expect(described_class.realtime_refresh?(agent)).to be_truthy
        end
      end
    end
  end
end
# rubocop:enable RSpec/PredicateMatcher
