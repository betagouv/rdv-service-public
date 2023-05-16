# frozen_string_literal: true

describe CustomDeviseMailer, "#domain" do
  subject(:sent_email) { described_class.reset_password_instructions(user, "t0k3n") }

  def expect_to_use_domain(domain)
    expect(sent_email.body).to include(domain.host_name)
    # L'adresse support@rdv-solidarites.fr est utilisée comme adresse de support
    # à la fois sur le domaine RDV Solidarité et le domaine RDV Aide Numérique.
    # En revanche on adapte le nom affiché pour que ce soit dans l'inbox du destinataire.
    expect(sent_email[:from].unparsed_value).to match(%("#{domain.name}" <support@rdv-solidarites.fr>))
  end

  context "when user has no RDV" do
    let(:user) { create(:user) }

    it "uses RDV_SOLIDARITES" do
      expect_to_use_domain(Domain::RDV_SOLIDARITES)
    end
  end

  context "when user only has RDV Solidarités rdvs" do
    let!(:organisation) { create(:organisation, verticale: :rdv_solidarites) }
    let!(:user) { create(:user) }
    let!(:rdvs) { create_list(:rdv, 2, organisation: organisation, users: [user]) }

    it "uses RDV_SOLIDARITES" do
      expect_to_use_domain(Domain::RDV_SOLIDARITES)
    end
  end

  context "when user has some rdvs" do
    let!(:user) { create(:user) }
    let!(:rdvs) { create_list(:rdv, 2, organisation: organisation, users: [user]) }

    context "in a RDV Insertion organisation" do
      let!(:organisation) { create(:organisation, verticale: :rdv_insertion) }

      it "uses RDV_SOLIDARITES" do
        expect_to_use_domain(Domain::RDV_SOLIDARITES)
      end
    end

    context "in a RDV Aide Numerique organisation" do
      let!(:organisation) { create(:organisation, verticale: :rdv_aide_numerique) }

      it "uses RDV_AIDE_NUMERIQUE" do
        expect_to_use_domain(Domain::RDV_AIDE_NUMERIQUE)
      end
    end

    context "in a RDV Mairie organisation" do
      let!(:organisation) { create(:organisation, verticale: :rdv_mairie) }

      it "uses RDV_MAIRIE" do
        expect_to_use_domain(Domain::RDV_MAIRIE)
      end
    end
  end

  context "when user has mixed RDV domains and most recent is rdv_aide_numerique" do
    let!(:user) { create(:user) }
    let!(:old_domain_organisation) { create(:organisation, verticale: :rdv_solidarites) }
    let!(:old_domain_organisation2) { create(:organisation, verticale: :rdv_insertion) }
    let!(:new_domain_organisation) { create(:organisation, verticale: :rdv_aide_numerique) }
    let!(:recent_rdv) { create(:rdv, organisation: new_domain_organisation, created_at: 2.days.ago, users: [user]) }
    let!(:old_rdv) { create(:rdv, organisation: old_domain_organisation, created_at: 3.months.ago, users: [user]) }
    let!(:old_rdv2) { create(:rdv, organisation: old_domain_organisation2, created_at: 4.months.ago, users: [user]) }

    it "uses the domain of the most recently created rdv" do
      expect_to_use_domain(Domain::RDV_AIDE_NUMERIQUE)
    end
  end

  context "when user has mixed RDV domains and most recent is rdv_solidarites" do
    let!(:user) { create(:user) }
    let!(:old_domain_organisation) { create(:organisation, verticale: :rdv_aide_numerique) }
    let!(:old_domain_organisation2) { create(:organisation, verticale: :rdv_insertion) }
    let!(:new_domain_organisation) { create(:organisation, verticale: :rdv_solidarites) }
    let!(:recent_rdv) { create(:rdv, organisation: new_domain_organisation, created_at: 2.days.ago, users: [user]) }
    let!(:old_rdv) { create(:rdv, organisation: old_domain_organisation, created_at: 3.months.ago, users: [user]) }
    let!(:old_rdv2) { create(:rdv, organisation: old_domain_organisation2, created_at: 4.months.ago, users: [user]) }

    it "uses the domain of the most recently created rdv" do
      expect_to_use_domain(Domain::RDV_SOLIDARITES)
    end
  end

  context "when user has mixed RDV domains and most recent is rdv_insertion" do
    let!(:user) { create(:user) }
    let!(:old_domain_organisation) { create(:organisation, verticale: :rdv_solidarites) }
    let!(:old_domain_organisation2) { create(:organisation, verticale: :rdv_aide_numerique) }
    let!(:new_domain_organisation) { create(:organisation, verticale: :rdv_insertion) }
    let!(:recent_rdv) { create(:rdv, organisation: new_domain_organisation, created_at: 2.days.ago, users: [user]) }
    let!(:old_rdv) { create(:rdv, organisation: old_domain_organisation, created_at: 3.months.ago, users: [user]) }
    let!(:old_rdv2) { create(:rdv, organisation: old_domain_organisation2, created_at: 4.months.ago, users: [user]) }

    it "uses the domain of the most recently created rdv" do
      expect_to_use_domain(Domain::RDV_SOLIDARITES)
    end
  end
end
