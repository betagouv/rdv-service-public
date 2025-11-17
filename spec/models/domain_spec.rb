RSpec.describe Domain do
  it "has domains initialized with all the required keys" do
    Domain::ALL.each do |domain|
      expect(domain.to_h.keys).to match_array(described_class.members)
    end
  end

  describe "#reply_host_name" do
    context "en prod" do
      before { allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new("production")) }

      it "renvoie les bons domaines" do
        expect(described_class.find("RDV_SOLIDARITES").reply_host_name).to eq("reply.rdv-solidarites.fr")
        expect(described_class.find("RDV_AIDE_NUMERIQUE").reply_host_name).to eq("reply.rdv-aide-numerique.fr")
        expect(described_class.find("RDV_SERVICE_PUBLIC").reply_host_name).to eq("reply.rdv-service-public.fr")
      end
    end

    context "en demo" do
      before { allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new("production")) }

      stub_env_with(RDV_SOLIDARITES_INSTANCE_NAME: "DEMO")

      it "renvoie les bons domaines" do
        expect(described_class.find("RDV_SOLIDARITES").reply_host_name).to eq("reply.demo.rdv-solidarites.fr")
        expect(described_class.find("RDV_AIDE_NUMERIQUE").reply_host_name).to eq("reply.demo.rdv-aide-numerique.fr")
        expect(described_class.find("RDV_SERVICE_PUBLIC").reply_host_name).to eq("reply.demo.rdv-service-public.fr")
      end
    end

    context "en staging" do
      before { allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new("production")) }

      stub_env_with(RDV_SOLIDARITES_INSTANCE_NAME: "STAGING")

      it "renvoie les bons domaines" do
        expect(described_class.find("RDV_SOLIDARITES").reply_host_name).to be_nil
        expect(described_class.find("RDV_AIDE_NUMERIQUE").reply_host_name).to be_nil
        expect(described_class.find("RDV_SERVICE_PUBLIC").reply_host_name).to eq("reply.staging.rdv-service-public.fr")
      end
    end
  end
end
