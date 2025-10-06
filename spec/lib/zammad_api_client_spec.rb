RSpec.describe ZammadApiClient, type: :service do
  stub_env_with ZAMMAD_API_TOKEN: "abcd1234efgh"

  describe ".create_ticket" do
    context "fonctionne correctement" do
      it "retourne des infos sur le ticket créé" do
        stub_request(:post, "https://zammad10.ethibox.fr/api/v1/tickets")
          .with(headers: { Authorization: "Token token=abcd1234efgh" })
          .to_return(
            status: 201,
            headers: { "Content-Type": "application/json" },
            body: <<~JSON
              {
                "id": 1123,
                "customer_id": 445,
                "number": "2204",
                "title": "J’ai besoin d’aide"
              }
            JSON
          )
        result = described_class.create_ticket(
          sender_role: :usager,
          subject: "J’ai besoin d’aide",
          email: "jean@jacques.fr",
          body: "Je ne sais plus comment annuler mon RDV\nmerci!"
        )
        expect(result).to be_a ZammadApiClient::Ticket
        expect(result.id).to eq 1123
        expect(result.customer_id).to eq 445
      end
    end

    context "erreur 403" do
      it "lève une erreur" do
        stub_request(:post, "https://zammad10.ethibox.fr/api/v1/tickets")
          .with(headers: { Authorization: "Token token=abcd1234efgh" })
          .to_return(
            status: 403,
            headers: { "Content-Type": "application/json" },
            body: %({ "error": "unauthorized" })
          )
        expect do
          described_class.create_ticket(
            sender_role: :usager,
            subject: "J’ai besoin d’aide",
            email: "jean@jacques.fr",
            body: "Je ne sais plus comment annuler mon RDV\nmerci!"
          )
        end.to raise_error Faraday::Error
      end
    end
  end
end
