RSpec.describe Users::NoReplyMailer, type: :mailer do
  describe "#no_reply" do
    context "l’usager a répondu à l’adresse no-reply du même environnement" do
      let(:source_mail) do
        Mail.new do
          from "jeanne@barret.fr"
          to "ne-pas-repondre@reply.rdv-solidarites-test.localhost"
        end
      end

      it "répond depuis la même adresse no-reply" do
        mail = described_class.with(source_mail:).no_reply
        expect(mail[:from].to_s).to eq(%("Ne pas répondre - RDV Solidarités" <ne-pas-repondre@reply.rdv-solidarites-test.localhost>))
        expect(mail.to).to eq(["jeanne@barret.fr"])
      end
    end

    context "l’usager a répondu à une adresse no-reply d’un autre environnement" do
      let(:source_mail) do
        Mail.new do
          from "jeanne@barret.fr"
          to "ne-pas-repondre@reply.rdv-solidarites.fr"
        end
      end

      it "répond depuis l’adresse no-reply de l’environnement courant" do
        mail = described_class.with(source_mail:).no_reply
        expect(mail[:from].to_s).to eq(%("Ne pas répondre - RDV Solidarités" <ne-pas-repondre@reply.rdv-solidarites-test.localhost>))
        expect(mail.to).to eq(["jeanne@barret.fr"])
      end
    end

    context "l’adresse n’est pas reconnaissable" do
      let(:source_mail) do
        Mail.new do
          from "jeanne@barret.fr"
          to "adresse@surprenante.fr"
        end
      end

      it "répond depuis l’adresse no-reply de l’environnement courant" do
        expect { described_class.with(source_mail:).no_reply.deliver_now }.to raise_exception Users::NoReplyMailer::UnrecognizableEmailAddressError
      end
    end
  end
end
