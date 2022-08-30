# frozen_string_literal: true

describe User::DomainConcern do
  subject(:user_domain) { user.domain }

  let(:motif_solidarites) { create(:motif, service: create(:service, :social)) }
  let(:motif_numerique) { create(:motif, service: create(:service, :conseiller_numerique)) }

  context "when user has no RDV" do
    let(:user) { create(:user, rdvs: []) }

    it { is_expected.to eq(Domain::RDV_SOLIDARITES) }
  end

  context "when user only RDV Solidarité RDVs" do
    let!(:organisation) { create(:organisation, new_domain_beta: true) }
    let(:user) { create(:user, rdvs: create_list(:rdv, 2, organisation: organisation, motif: motif_solidarites)) }

    it { is_expected.to eq(Domain::RDV_SOLIDARITES) }
  end

  context "when user only RDV Aide Numérique RDVs but organisation not in beta program" do
    let!(:organisation) { create(:organisation, new_domain_beta: false) }
    let(:user) { create(:user, rdvs: create_list(:rdv, 2, organisation: organisation, motif: motif_numerique)) }

    it { is_expected.to eq(Domain::RDV_SOLIDARITES) }
  end

  context "when user only RDV Aide Numérique RDVs and organisation is in beta program" do
    let!(:organisation) { create(:organisation, new_domain_beta: true) }
    let(:user) { create(:user, rdvs: create_list(:rdv, 2, organisation: organisation, motif: motif_numerique)) }

    it { is_expected.to eq(Domain::RDV_AIDE_NUMERIQUE) }
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

    it { is_expected.to eq(Domain::RDV_AIDE_NUMERIQUE) }
  end
end
