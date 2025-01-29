RSpec.describe RelativeUserForm do
  context "un first_name et un last_name valide" do
    it "créé un user" do
      form = described_class.new(user: User.new)
      expect { form.submit(first_name: "Jean", last_name: "Jacques") }.to change(User, :count).by(1)
      form.user.reload
      expect(form.user.first_name).to eq("Jean")
      expect(form.user.last_name).to eq("Jacques")
    end
  end

  context "last_name manquant" do
    it "ne créé pas un user et les erreurs du user sont accessibles sur le form object" do
      form = described_class.new(user: User.new)
      expect { form.submit(first_name: "Jean") }.not_to change(User, :count)
      expect(form.errors.count).to eq 1
      expect(form.errors.first.attribute).to eq :last_name
      expect(form.errors.first.type).to eq :blank
    end
  end

  context "numéro de pré-demande ANTS requis et" do
    include_context "rdv_mairie_api_authentication"
    before { stub_ants_status_ok("VALID12345", status: "validated", appointments: []) }

    let(:form) { described_class.new(user: User.new, ants_pre_demande_number_required: true) }

    context "numéro passé et valide" do
      it "créé un user" do
        expect { form.submit(first_name: "Jean", last_name: "Jacques", ants_pre_demande_number: "VALID12345") }.to change(User, :count).by(1)
        form.user.reload
        expect(form.user.first_name).to eq("Jean")
        expect(form.user.last_name).to eq("Jacques")
        expect(form.user.ants_pre_demande_number).to eq("VALID12345")
      end
    end

    context "numéro pas passé du tout" do
      it "ne créé pas un user et l’erreur est accessible sur le form object" do
        expect { form.submit(first_name: "Jean", last_name: "Jacques") }.not_to change(User, :count)
        expect(form.errors.count).to eq 1
        expect(form.errors.first.attribute).to eq :ants_pre_demande_number
        expect(form.errors.first.type).to eq :blank
      end
    end

    context "numéro invalide" do
      it "ne créé pas un user et l’erreur est accessible sur le form object" do
        expect { form.submit(first_name: "Jean", last_name: "Jacques", ants_pre_demande_number: "notval") }.not_to change(User, :count)
        expect(form.errors.count).to eq 1
        expect(form.errors.first.attribute).to eq :ants_pre_demande_number
        expect(form.errors.first.type).to eq "doit comporter 10 chiffres et lettres"
      end
    end
  end
end
