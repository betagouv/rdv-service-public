RSpec.describe TimeoutHelper do
  describe ".long_running_block_warn" do
    context "when block runs faster than delay" do
      it "does not call the callback" do
        expect(Rails.logger).to receive(:debug).once.with("End of main block reached")

        callback = -> { Rails.logger.warn("Callback called!") }
        described_class.long_running_block_warn(after: 0.2.seconds, callback: callback) do
          sleep 0.1
          Rails.logger.debug("End of main block reached")
        end
      end
    end

    context "when block finishes after the delay" do
      it "calls the callback" do
        expect(Rails.logger).to receive(:warn).once.with("Callback called!").ordered
        expect(Rails.logger).to receive(:debug).once.with("End of main block reached").ordered

        callback = -> { Rails.logger.warn("Callback called!") }
        described_class.long_running_block_warn(after: 0.1.seconds, callback: callback) do
          sleep 0.2
          Rails.logger.debug("End of main block reached")
        end
      end
    end
  end
end
