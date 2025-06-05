require "rails_helper"

RSpec.describe CreateChatwootConversationJob do
  describe "#perform" do
    let(:chatwoot_contact) { { "id" => 123, "contact_inboxes" => [{ "inbox" => { "id" => "1" }, "source_id" => "source123" }] } }
    let(:chatwoot_conversation) { { "id" => 46, "messages" => [] } }
    let(:mailer_instance) { instance_double(Users::DemandesSupportMailer) }
    let(:message_delivery) { instance_double(ActionMailer::MessageDelivery) }

    before do
      allow(ChatwootApiClient).to receive(:upsert_contact).and_return(chatwoot_contact)
      allow(ChatwootApiClient).to receive(:create_conversation).and_return(chatwoot_conversation)
      allow(ChatwootApiClient).to receive(:create_message).and_return({ "id" => 789 })
      allow(Users::DemandesSupportMailer).to receive(:with).and_return(mailer_instance)
      allow(mailer_instance).to receive(:conversation_created).and_return(message_delivery)
      allow(message_delivery).to receive(:deliver_later)
    end

    specify do
      described_class.perform_now(
        first_name: "Sophie",
        last_name: "Dubois",
        email: "sophie.dubois@example.com",
        phone_number: "0611223344",
        sujet: "Problème de connexion",
        message: "Je n'arrive pas à me connecter à mon compte.",
        role: "user",
        domain: "RDV_SOLIDARITES"
      )

      expect(ChatwootApiClient).to have_received(:upsert_contact).with(
        email: "sophie.dubois@example.com",
        first_name: "Sophie",
        last_name: "Dubois",
        phone_number: "0611223344",
        role: "user"
      )
      expect(ChatwootApiClient).to have_received(:create_conversation).with(contact: chatwoot_contact)
      expect(ChatwootApiClient).to have_received(:create_message).with(
        conversation: chatwoot_conversation,
        content: "Problème de connexion\n\nJe n'arrive pas à me connecter à mon compte.",
        message_type: "outgoing",
        private: true
      )
      expect(Users::DemandesSupportMailer).to have_received(:with).with(
        conversation_id: 46,
        email: "sophie.dubois@example.com",
        domain: "RDV_SOLIDARITES",
        message: "Je n'arrive pas à me connecter à mon compte.",
        sujet: "Problème de connexion"
      )
      expect(mailer_instance).to have_received(:conversation_created)
      expect(message_delivery).to have_received(:deliver_later)
    end
  end
end
