# frozen_string_literal: true

class OrganizationBlueprint < Blueprinter::Base
  identifier :id

  field :name, name: :label
  field :territory_id, name: :group_id
  fields :phone_number, :email, :website
  field :public_link do |organisation, _|
    Rails.application.routes.url_helpers.public_link_to_org_url(
      organisation_id: organisation,
      host: organisation.domain.dns_domain_name
    )
  end
end
