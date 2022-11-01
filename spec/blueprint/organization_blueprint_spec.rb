# frozen_string_literal: true

RSpec.describe OrganizationBlueprint do
  describe "render" do
    it "contains the organisation data" do
      organisation = build_stubbed(:organisation, :with_contact)
      parsed_organization = JSON.parse(described_class.render(organisation, root: :organization)).with_indifferent_access
      expect(parsed_organization[:organization]).to match(
        {
          id: organisation.id,
          group_id: organisation.territory_id,
          label: organisation.name,
          email: organisation.email,
          website: organisation.website,
          phone_number: organisation.phone_number,
          public_link: Rails.application.routes.url_helpers.public_link_to_org_url(
            organisation_id: organisation,
            host: organisation.domain.dns_domain_name
          ),
        }
      )
    end
  end
end
