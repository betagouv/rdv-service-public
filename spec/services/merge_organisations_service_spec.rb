RSpec.describe MergeOrganisationsService do
  subject(:service) { described_class.new(source_organisation: source_organisation.reload, target_organisation: target_organisation.reload) }

  let!(:territory) { create(:territory) }
  let!(:source_organisation) { create(:organisation, territory: territory, name: "Source Org") }
  let!(:target_organisation) { create(:organisation, territory: territory, name: "Target Org") }

  describe "migrating agents" do
    let!(:agent_in_source_org) { create(:agent, basic_role_in_organisations: [source_organisation], first_name: "Bruce", last_name: "SOURCE") }
    let!(:agent_in_target_org) { create(:agent, basic_role_in_organisations: [target_organisation], first_name: "Ginette", last_name: "TARGET") }
    let!(:agent_in_both) { create(:agent, basic_role_in_organisations: [source_organisation, target_organisation], first_name: "Jean-Claude", last_name: "VAN DAMME") }

    it "adds agents to target org and removes them from source org" do
      expect(source_organisation.agents).to contain_exactly(agent_in_source_org, agent_in_both)
      expect(target_organisation.agents).to contain_exactly(agent_in_target_org, agent_in_both)

      expect(service).to be_valid
      service.perform

      expect(source_organisation.reload.agents).to be_empty
      expect(target_organisation.reload.agents).to contain_exactly(agent_in_source_org, agent_in_target_org, agent_in_both)
    end

    context "when agent has a different access level in each organisation" do
      before do
        agent_in_both.role_in_organisation(source_organisation).update!(access_level: AgentRole::ACCESS_LEVEL_ADMIN)
      end

      it "raises an error" do
        service.validate
        expect(service.errors.full_messages.map(&:squish))
          .to include("L'agent Jean-Claude VAN DAMME (ID=#{agent_in_both.id}) a un rôle admin dans Source Org mais un rôle basic dans Target Org")
      end
    end
  end

  describe "migrating users" do
    describe "active user" do
      let!(:user_in_source_org) { create(:user, organisations: [source_organisation]) }
      let!(:user_in_target_org) { create(:user, organisations: [target_organisation]) }
      let!(:user_in_both) { create(:user, organisations: [source_organisation, target_organisation]) }

      it "adds users to target org and removes them from source org" do
        expect(source_organisation.users).to contain_exactly(user_in_source_org, user_in_both)
        expect(target_organisation.users).to contain_exactly(user_in_target_org, user_in_both)

        expect(service).to be_valid
        service.perform

        expect(source_organisation.users).to be_empty
        expect(target_organisation.users).to contain_exactly(user_in_source_org, user_in_target_org, user_in_both)
      end
    end

    describe "soft deleted users" do
      let!(:soft_deleted_user) { create(:user, organisations: [source_organisation], deleted_at: 2.days.ago) }

      it "are also migrated to target org" do
        expect { service.perform }
          .to change { target_organisation.users.unscope(where: :deleted_at).find_by(id: soft_deleted_user.id) }.from(nil)
      end
    end
  end

  describe "migrating motifs" do
    let!(:motif_in_source_org) { create(:motif, organisation: source_organisation) }
    let!(:motif_in_target_org) { create(:motif, organisation: target_organisation) }

    it "move motifs from source org to target org" do
      expect(service.valid?(:expect_identical_motifs)).to be(true)
      service.perform

      expect(source_organisation.motifs).to be_empty
      expect(target_organisation.motifs).to contain_exactly(motif_in_source_org, motif_in_target_org)
    end

    context "when a strictly identical motif exists in target organisation" do
      let!(:strictly_identical_motif) do
        motif_in_source_org.dup.tap do |duplicate_motif|
          duplicate_motif.organisation = target_organisation
          duplicate_motif.save!
        end
      end

      it "links all plages in source org to the existing motif in target org" do
        plage_in_source_org = create(:plage_ouverture, organisation: source_organisation, motifs: [motif_in_source_org])

        expect(service.valid?(:expect_identical_motifs)).to be(true)
        service.perform

        expect(plage_in_source_org.reload.motifs).to eq([strictly_identical_motif])
      end

      it "links all RDVs in source org to the existing motif in target org" do
        rdv_in_source_org = create(:rdv, organisation: source_organisation, motif: motif_in_source_org)

        expect(service.valid?(:expect_identical_motifs)).to be(true)
        service.perform

        expect(rdv_in_source_org.reload.motif).to eq(strictly_identical_motif)
      end
    end

    context "when a similar motif with different secondary attributes exists in target org" do
      let!(:motif_in_source_org) { create(:motif, organisation: source_organisation, default_duration_in_min: 45, color: "#FFFFFF") }
      let!(:motif_in_target_org) { create(:motif, organisation: target_organisation) }
      let!(:similar_motif) do
        motif_in_source_org.dup.tap do |duplicate_motif|
          duplicate_motif.organisation = target_organisation
          duplicate_motif.color = "#000000"
          duplicate_motif.default_duration_in_min = 60
          duplicate_motif.instruction_for_rdv = "Not the same instructions"
          duplicate_motif.save!
        end
      end

      it "raises an error" do
        expect(service.valid?(:expect_identical_motifs)).to be(false)
        expected_error = <<~ERROR
          Les motifs #{motif_in_source_org.id} et #{similar_motif.id} (#{motif_in_source_org.name}) sont des doublons mais ont les différences suivantes :
            default_duration_in_min: - 45 + 60
            instruction_for_rdv: - nil + "Not the same instructions"
        ERROR
        expect(service.errors.full_messages).to include(expected_error)
      end
    end

    describe "archived motifs" do
      let!(:archived_motif_in_source_org) { create(:motif, organisation: source_organisation, deleted_at: 2.days.ago) }
      let!(:archived_motif_in_target_org) { archived_motif_in_source_org.tap { _1.update!(organisation: target_organisation) } }

      it "assigns them to the target org event if there are duplicates" do
        expect(service.valid?).to be(true)
        service.perform

        expect(target_organisation.motifs.reload).to include(archived_motif_in_source_org, archived_motif_in_target_org)
      end
    end
  end

  describe "migrating plages" do
    let!(:plage_in_source_org) { create(:plage_ouverture, organisation: source_organisation) }
    let!(:plage_in_target_org) { create(:plage_ouverture, organisation: target_organisation) }

    it "adds plages to target org and removes them from source org" do
      expect(service).to be_valid
      service.perform

      expect(source_organisation.plage_ouvertures).to be_empty
      expect(target_organisation.plage_ouvertures).to contain_exactly(plage_in_source_org, plage_in_target_org)
    end
  end

  describe "migrating exports" do
    let!(:export_only_of_source_org) { create(:export, organisation_ids: [source_organisation.id]) }
    let!(:export_only_of_target_org) { create(:export, organisation_ids: [target_organisation.id]) }
    let!(:export_of_both_orgs) { create(:export, organisation_ids: [source_organisation.id, target_organisation.id]) }

    it "deletes all existing exports that reference the source org" do
      expect { service.perform }.to change(Export, :count).by(-2)
      expect(Export.all).to contain_exactly(export_only_of_target_org)
    end
  end

  describe "migrating lieux" do
    let!(:lieu_in_source_org) { create(:lieu, organisation: source_organisation) }
    let!(:lieu_in_target_org) { create(:lieu, organisation: target_organisation) }

    it "adds lieux to target org and removes them from source org" do
      expect(service).to be_valid
      service.perform

      expect(source_organisation.lieux).to be_empty
      expect(target_organisation.lieux).to contain_exactly(lieu_in_source_org, lieu_in_target_org)
    end
  end

  describe "migrating RDVs" do
    let!(:rdv_in_source_org) { create(:rdv, organisation: source_organisation) }
    let!(:rdv_in_target_org) { create(:rdv, organisation: target_organisation) }

    it "adds RDVs to target org and removes them from source org" do
      expect(service).to be_valid
      service.perform

      expect(source_organisation.rdvs).to be_empty
      expect(target_organisation.rdvs).to contain_exactly(rdv_in_source_org, rdv_in_target_org)
      expect(rdv_in_source_org.motif.reload.organisation).to eq(target_organisation) # double check that the motif is moved as well
    end
  end

  describe "migrating receipts" do
    let!(:receipt_in_source_org) { create(:receipt, rdv: create(:rdv, organisation: source_organisation)) }
    let!(:receipt_in_target_org) { create(:receipt, rdv: create(:rdv, organisation: target_organisation)) }

    it "adds receipts to target org and removes them from source org" do
      expect(service).to be_valid
      service.perform

      expect(source_organisation.receipts).to be_empty
      expect(target_organisation.receipts).to contain_exactly(receipt_in_source_org, receipt_in_target_org)
    end
  end

  describe "migrating sector attributions" do
    let!(:sector_attribution_in_source_org) { create(:sector_attribution, organisation: source_organisation) }
    let!(:sector_attribution_in_target_org) { create(:sector_attribution, organisation: target_organisation) }

    it "adds sector_attributions to target org and removes them from source org" do
      expect(service).to be_valid
      service.perform

      expect(source_organisation.sector_attributions).to be_empty
      expect(target_organisation.sector_attributions).to contain_exactly(sector_attribution_in_source_org, sector_attribution_in_target_org)
    end
  end

  describe "migrating webhook endpoints" do
    let!(:webhook_endpoint_in_source_org) { create(:webhook_endpoint, organisation: source_organisation, target_url: "https://connecteur-outlook.haute-savoie.fr/") }
    let!(:webhook_endpoint_in_target_org) { create(:webhook_endpoint, organisation: target_organisation, target_url: "https://connecteur-zimbra.haute-savoie.fr/") }

    it "adds webhook_endpoints to target org and removes them from source org" do
      expect(service).to be_valid
      service.perform

      expect(source_organisation.webhook_endpoints.reload).to be_empty
      expect(target_organisation.webhook_endpoints.reload).to contain_exactly(webhook_endpoint_in_source_org, webhook_endpoint_in_target_org)
    end

    context "when a webhook with same URL and subscriptions exists" do
      let!(:webhook_endpoint_in_source_org) { create(:webhook_endpoint, organisation: source_organisation, target_url: "https://connecteur-outlook.haute-savoie.fr/", subscriptions: %w[rdv]) }
      let!(:webhook_endpoint_in_target_org) { create(:webhook_endpoint, organisation: target_organisation, target_url: "https://connecteur-zimbra.haute-savoie.fr/") }
      let!(:strictly_identical_webhook)     { create(:webhook_endpoint, organisation: target_organisation, target_url: "https://connecteur-outlook.haute-savoie.fr/", subscriptions: %w[rdv]) }

      it "just deletes the webhook in source org" do
        expect { service.perform }.to change(WebhookEndpoint, :count).by(-1)
        expect(WebhookEndpoint.all).to contain_exactly(webhook_endpoint_in_target_org, strictly_identical_webhook)
      end
    end

    context "when a webhook exists with same URL but different subscriptions" do
      let!(:webhook_endpoint_in_source_org) { create(:webhook_endpoint, organisation: source_organisation, target_url: "https://connecteur-outlook.haute-savoie.fr/", subscriptions: %w[rdv]) }
      let!(:webhook_endpoint_in_target_org) { create(:webhook_endpoint, organisation: target_organisation, target_url: "https://connecteur-zimbra.haute-savoie.fr/") }
      let!(:webhook_same_url)               { create(:webhook_endpoint, organisation: target_organisation, target_url: "https://connecteur-outlook.haute-savoie.fr/", subscriptions: %w[rdv absence]) }

      it "raises an error" do
        expect(service).to be_invalid
        expect(service.errors.full_messages.map(&:squish))
          .to include("Les webhooks #{webhook_endpoint_in_source_org.id} et #{webhook_same_url.id} ont la même URL mais des subscriptions différentes")
      end
    end
  end

  describe "additional validations" do
    context "when the organisations are from different territories" do
      let!(:source_organisation) { create(:organisation, territory: create(:territory)) }
      let!(:target_organisation) { create(:organisation, territory: create(:territory)) }

      it "raises an error" do
        expect(service).to be_invalid
        expect(service.errors.full_messages.map(&:squish)).to include("Les deux organisations doivent être dans le même territoire")
      end
    end
  end
end
