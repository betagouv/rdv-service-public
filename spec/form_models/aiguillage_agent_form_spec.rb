RSpec.describe AiguillageAgentForm do
  subject(:form) { described_class.new(raison: raison) }

  context "raison is gestion_agents" do
    let(:raison) { :gestion_agents }

    it { expect(form.should_redirect_to_demande_support?).to be false }
    it { expect(form.should_show_contact_admin_message?).to be true }
    it { expect(form.raison_label).to eq "Gérer les agents de mon organisation (ajout, suppression, droits)" }
  end

  context "raison is lieux_horaires" do
    let(:raison) { :lieux_horaires }

    it { expect(form.should_redirect_to_demande_support?).to be false }
    it { expect(form.should_show_contact_admin_message?).to be true }
  end

  context "raison is motifs_rdv" do
    let(:raison) { :motifs_rdv }

    it { expect(form.should_redirect_to_demande_support?).to be false }
    it { expect(form.should_show_contact_admin_message?).to be true }
  end

  context "raison is reservation_en_ligne" do
    let(:raison) { :reservation_en_ligne }

    it { expect(form.should_redirect_to_demande_support?).to be false }
    it { expect(form.should_show_contact_admin_message?).to be true }
  end

  context "raison is autre" do
    let(:raison) { :autre }

    it { expect(form.should_redirect_to_demande_support?).to be true }
    it { expect(form.should_show_contact_admin_message?).to be false }
    it { expect(form.raison_label).to eq "Autre raison" }
  end

  context "raison is blank" do
    let(:raison) { nil }

    it { expect(form.raison).to be_nil }
    it { expect(form.should_redirect_to_demande_support?).to be false }
    it { expect(form.should_show_contact_admin_message?).to be false }
  end

  context "raison is not a valid option" do
    let(:raison) { :n_importe_quoi }

    it { expect(form.raison).to be_nil }
    it { expect(form.should_show_contact_admin_message?).to be false }
  end
end
