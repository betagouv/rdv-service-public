# frozen_string_literal: true

describe CustomDeviseMailer, "#domain" do
  subject(:sent_email) { described_class.reset_password_instructions(user, "t0k3n") }

  let(:motif_solidarites) { create(:motif, service: create(:service, :social)) }
  let(:motif_numerique) { create(:motif, service: create(:service, :conseiller_numerique)) }

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

  context "when user only has RDV Aide Numérique RDVs but organisation not in beta program" do
    let!(:organisation) { create(:organisation, new_domain_beta: false) }
    let(:user) { create(:user, rdvs: create_list(:rdv, 2, organisation: organisation, motif: motif_numerique)) }

    it "uses RDV_SOLIDARITES" do
      expect_to_use_domain(Domain::RDV_SOLIDARITES)
    end
  end

  context "when user only has RDV Aide Numérique RDVs and organisation is in beta program" do
    let!(:organisation) { create(:organisation, new_domain_beta: true) }
    let(:user) { create(:user, rdvs: create_list(:rdv, 2, organisation: organisation, motif: motif_numerique)) }

    it "uses RDV_SOLIDARITES" do
      expect_to_use_domain(Domain::RDV_AIDE_NUMERIQUE)
    end
  end

  context "when user has mixed RDV domains (and organisation is in beta program)" do
    let!(:organisation) { create(:organisation, new_domain_beta: true) }
    let(:user) do
      mixed_rdvs = [
        create(:rdv, organisation: organisation, motif: motif_numerique, created_at: 2.days.ago),
        create(:rdv, organisation: organisation, motif: motif_solidarites, created_at: 4.days.ago),
        create(:rdv, organisation: organisation, motif: motif_numerique, created_at: 6.days.ago),
        create(:rdv, organisation: organisation, motif: motif_solidarites, created_at: 8.days.ago),
      ]
      create(:user, rdvs: mixed_rdvs)
    end

    it "uses RDV_SOLIDARITES" do
      expect_to_use_domain(Domain::RDV_AIDE_NUMERIQUE)
    end
  end
end
