RSpec.describe SmsSender, type: :service do
  let(:rdv) { create(:rdv) }
  let(:user) { create(:user) }
  let(:receipt_params) { { event: "rdv_created", rdv: rdv, user: user } }

  describe "#content" do
    subject { test_sms.content }

    let(:test_sms) { described_class.new("RdvSoli", "0612345678", content, "netsize", nil, receipt_params) }

    context "remove accents and weird chars" do
      let(:content) { "àáäâãèéëẽêìíïîĩòóöôõùúüûũñçÀÁÄÂÃÈÉËẼÊÌÍÏÎĨÒÓÖÔÕÙÚÜÛŨÑÇ" }

      it { is_expected.to eq("àaäaaèéeeeìiiiiòoöooùuüuuñcAAÄAAEÉEEEIIIIIOOÖOOUUÜUUÑC") }
    end

    context "oe character" do
      let(:content) { "Nœuds les mînes" }

      it { is_expected.to eq("Noeuds les mines") }
    end

    describe "instance name" do
      around do |example|
        with_modified_env(RDV_SOLIDARITES_INSTANCE_NAME: instance_name) do
          example.run
        end
      end

      let(:content) { "Contenu de test" }

      context "when instance name is blank" do
        let(:instance_name) { "" }

        it { is_expected.to eq("Contenu de test") }
      end

      context "when instance name is set" do
        let(:instance_name) { "TEST INSTANCE" }

        it { is_expected.to eq("TEST INSTANCE\nContenu de test") }
      end
    end
  end

  describe "receipt creation" do
    context "with netsize provider" do
      before do
        stub_netsize_ok
        described_class.perform_with("RdvSoli", "0612345678", "content", "netsize", "key", receipt_params)
      end

      it do
        receipt = Receipt.last
        expect(receipt).not_to be_nil
        expect(receipt).to have_attributes(event: "rdv_created", rdv: rdv, user: user, content: "content", sms_provider: "netsize")
      end
    end

    context "with smsfactor" do
      context "when sms is sent successfully" do
        before do
          stub_sms_factor_ok
          described_class.perform_with("RdvSoli", "0612345678", "content", "sms_factor", "key", receipt_params)
        end

        it do
          receipt = Receipt.last
          expect(receipt).not_to be_nil
          expect(receipt).to have_attributes(event: "rdv_created", rdv: rdv, user: user, content: "content", sms_provider: "sms_factor", sms_count: 1)
        end

        it "save remaining credits" do
          Redis.with_connection do |redis|
            expect(redis.get("SMS_FACTOR_REMAINING_CREDITS")).to eq("42")
          end
        end
      end

      context "when sms is not sent due to moderation" do
        before do
          stub_sms_factor_moderation
          described_class.perform_with("RdvSoli", "0612345678", "content", "sms_factor", "key", receipt_params)
        end

        it do
          receipt = Receipt.last
          expect(receipt).not_to be_nil
          expect(receipt).to have_attributes(event: "rdv_created", rdv: rdv, user: user, content: "content", sms_provider: "sms_factor", sms_count: 1)
        end

        it "save remaining credits" do
          Redis.with_connection do |redis|
            expect(redis.get("SMS_FACTOR_REMAINING_CREDITS")).to eq("42")
          end
        end
      end
    end
  end

  describe "requêtes HTTP vers les fournisseurs" do
    let(:perform_with) do
      ->(provider, api_key) { described_class.perform_with("RdvSoli", "0612345678", "Bonjour", provider, api_key, receipt_params) }
    end

    context "avec netsize" do
      let(:url) { "https://europe.ipx.com/restapi/v1/sms/send" }

      it "envoie un formulaire en basic auth" do
        stub = stub_request(:post, url)
          .with(
            basic_auth: %w[user pass],
            headers: { "Content-Type" => "application/x-www-form-urlencoded; charset=UTF-8" },
            body: {
              "destinationAddress" => "0612345678",
              "messageText" => "Bonjour",
              "originatingAddress" => "RdvSoli",
              "originatorTON" => "1",
              "maxConcatenatedMessages" => "10",
            }
          )
          .to_return(status: 200, body: { responseCode: 0, messageIds: [1, 2] }.to_json)

        perform_with.call("netsize", "user:pass")

        expect(stub).to have_been_requested
        expect(Receipt.last).to have_attributes(result: "delivered", sms_count: 2)
      end

      it "enregistre un échec sur un timeout" do
        stub_request(:post, url).to_timeout

        expect { perform_with.call("netsize", "user:pass") }.to raise_error(SmsSender::SmsSenderFailure, "NetSize timeout")
        expect(Receipt.last).to have_attributes(result: "failure", error_message: "NetSize timeout")
      end

      it "enregistre un échec sur une erreur HTTP" do
        stub_request(:post, url).to_return(status: 503, body: "")

        expect { perform_with.call("netsize", "user:pass") }.to raise_error(SmsSender::SmsSenderFailure, "NetSize HTTP error: 503")
      end
    end

    context "avec clever technologies" do
      let(:url) { "https://webservicesmultimedias.clever-is.fr/api/pushs" }

      it "envoie un JSON avec un header Authorization Basic" do
        stub = stub_request(:post, url)
          .with(
            headers: {
              "Content-Type" => "application/json; charset=UTF-8",
              "Authorization" => "Basic #{Base64.strict_encode64('user:pass')}",
            }
          ) { |req| JSON.parse(req.body) == { "datas" => { "text" => "Bonjour", "number_list" => "0612345678", "encodage" => 3 } } }
          .to_return(status: 201, body: { push: { nb_sms: 1 } }.to_json)

        perform_with.call("clever_technologies", "user:pass")

        expect(stub).to have_been_requested
        expect(Receipt.last).to have_attributes(result: "sent", sms_count: 1)
      end

      it "enregistre un échec quand le fournisseur renvoie une erreur HTTP" do
        stub_request(:post, url).to_return(status: 402, body: { errors: { credit: "Pas de crédit" } }.to_json)

        expect { perform_with.call("clever_technologies", "user:pass") }
          .to raise_error(SmsSender::SmsSenderFailure, "Clever Technologies HTTP error: 402")
      end

      it "enregistre un échec sur un timeout" do
        stub_request(:post, url).to_timeout

        expect { perform_with.call("clever_technologies", "user:pass") }
          .to raise_error(SmsSender::SmsSenderFailure, "Clever Technologies error: Timeout")
      end
    end
  end
end
