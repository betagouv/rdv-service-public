# frozen_string_literal: true

describe CustomDeviseMailer, "#domain" do
  subject(:user_domain) { described_class.reset_password_instructions(user, "t0k3n").body }

  let(:motif_solidarites) { create(:motif, service: create(:service, :social)) }
  let(:motif_numerique) { create(:motif, service: create(:service, :conseiller_numerique)) }

  context "when user has no RDV" do
    let(:user) { create(:user, rdvs: []) }

    it { is_expected.to include(Domain::RDV_SOLIDARITES.dns_domain_name) }
  end

  context "when user only has RDV Solidarité RDVs but the organisation uses the new domain name" do
    let!(:organisation) { create(:organisation, new_domain_beta: true) }
    let(:user) { create(:user, rdvs: create_list(:rdv, 2, organisation: organisation, motif: motif_solidarites)) }

    it { is_expected.to include(Domain::RDV_AIDE_NUMERIQUE.dns_domain_name) }
  end

  context "when user only has RDV Aide Numérique RDVs but organisation not in beta program" do
    let!(:organisation) { create(:organisation, new_domain_beta: false) }
    let(:user) { create(:user, rdvs: create_list(:rdv, 2, organisation: organisation, motif: motif_numerique)) }

    it { is_expected.to include(Domain::RDV_SOLIDARITES.dns_domain_name) }
  end

  context "when user only has RDV Aide Numérique RDVs and organisation is in beta program" do
    let!(:organisation) { create(:organisation, new_domain_beta: true) }
    let(:user) { create(:user, rdvs: create_list(:rdv, 2, organisation: organisation, motif: motif_numerique)) }

    it { is_expected.to include(Domain::RDV_AIDE_NUMERIQUE.dns_domain_name) }
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

    it { is_expected.to include(Domain::RDV_AIDE_NUMERIQUE.dns_domain_name) }
  end
end
