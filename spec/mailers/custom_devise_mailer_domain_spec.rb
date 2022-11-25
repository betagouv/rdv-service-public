# frozen_string_literal: true

describe CustomDeviseMailer, "#domain" do
  subject(:sent_email) { described_class.reset_password_instructions(user, "t0k3n") }

  def expect_to_use_domain(domain)
    expect(sent_email.body).to include(domain.dns_domain_name)
    # L'adresse support@rdv-solidarites.fr est utilisée comme adresse de support
    # à la fois sur le domaine RDV Solidarité et le domaine RDV Aide Numérique.
    # En revanche on adapte le nom affiché pour que ce soit dans l'inbox du destinataire.
    expect(sent_email[:from].to_s).to eq(%("#{domain.name}" <support@rdv-solidarites.fr>))
  end

  context "when user has no RDV" do
    let(:user) { create(:user, rdvs: []) }

    it "uses RDV_SOLIDARITES" do
      expect_to_use_domain(Domain::RDV_SOLIDARITES)
    end
  end

  context "when user only has RDV Solidarités rdvs" do
    let!(:organisation) { create(:organisation, new_domain_beta: false) }
    let(:user) { create(:user, rdvs: create_list(:rdv, 2, organisation: organisation)) }

    it "uses RDV_SOLIDARITES" do
      expect_to_use_domain(Domain::RDV_SOLIDARITES)
    end
  end

  context "when user only has RDV Aide Numérique rdvs" do
    let!(:organisation) { create(:organisation, new_domain_beta: true) }
    let(:user) { create(:user, rdvs: create_list(:rdv, 2, organisation: organisation)) }

    it "uses RDV_AIDE_NUMERIQUE" do
      expect_to_use_domain(Domain::RDV_AIDE_NUMERIQUE)
    end
  end

  context "when user has mixed RDV domains (and organisation is in beta program)" do
    let!(:old_domain_organisation) { create(:organisation, new_domain_beta: false) }
    let!(:new_domain_organisation) { create(:organisation, new_domain_beta: true) }
    let!(:recent_rdv) { build(:rdv, organisation: new_domain_organisation, created_at: 2.days.ago) }
    let!(:old_rdv) { build(:rdv, organisation: old_domain_organisation, created_at: 3.months.ago) }
    let!(:user) { create(:user, rdvs: [recent_rdv, old_rdv]) }

    it "uses the domain of the most recently created rdv" do
      expect_to_use_domain(Domain::RDV_AIDE_NUMERIQUE)
    end
  end
end
