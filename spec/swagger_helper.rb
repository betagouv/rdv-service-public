# frozen_string_literal: true

require "rails_helper"

RSpec.configure do |config|
  # Specify a root folder where Swagger JSON files are generated
  # NOTE: If you're using the rswag-api to serve API descriptions, you'll need
  # to ensure that it's configured to serve Swagger from the same folder
  config.swagger_root = Rails.root.join("swagger").to_s

  # Define one or more Swagger documents and provide global metadata for each one
  # When you run the 'rswag:specs:swaggerize' rake task, the complete Swagger will
  # be generated at the provided relative path under swagger_root
  # By default, the operations defined in spec files are added to the first
  # document below. You can override this behavior by adding a swagger_doc tag to the
  # the root example_group in your specs, e.g. describe '...', swagger_doc: 'v2/swagger.json'
  config.swagger_docs = {
    "v1/api.json" => {
      openapi: "3.0.1",
      info: {
        title: "API RDV Solidarités V1",
        version: "v1",
        description: File.read(Rails.root.join("docs/api/description_api.md")),
      },
      components: {
        securitySchemes: {
          access_token: {
            type: :apiKey,
            name: "access-token",
            in: :header,
          },
          uid: {
            type: :apiKey,
            name: "uid",
            in: :header,
          },
          client: {
            type: :apiKey,
            name: "client",
            in: :header,
          },
        },
        schemas: {
          get_rdvs: {
            type: "object",
            properties: {
              rdvs: {
                type: "array",
                items: { "$ref" => "#/components/schemas/rdv" },
              },
              meta: { "$ref" => "#/components/schemas/meta" },
            },
            required: %w[rdvs meta],
          },
          rdv: {
            type: "object",
            properties: {
              id: { type: "integer" },
              address: { type: "string" },
              agents: {
                type: "array",
                items: { "$ref" => "#/components/schemas/agent" },
              },
              cancelled_at: { type: "string", nullable: true },
              collectif: { type: "boolean" },
              context: { type: "string", nullable: true },
              created_by: { type: "string", enum: %w[agent user file_attente] },
              deleted_at: { type: "string", nullable: true },
              duration_in_min: { type: "integer" },
              ends_at: { type: "string" },
              lieu: { "$ref" => "#/components/schemas/lieu" },
              max_participants_count: { type: "integer", nullable: true },
              motif: { "$ref" => "#/components/schemas/motif" },
              name: { type: "string", nullable: true },
              organisation: { "$ref" => "#/components/schemas/organisation" },
              rdvs_users: {
                type: "array",
                items: { "$ref" => "#/components/schemas/rdvs_user" },
              },
              starts_at: { type: "string" },
              status: { type: "string", enum: %w[unknown waiting seen excused revoked noshow] },
              users: {
                type: "array",
                items: { "$ref" => "#/components/schemas/user" },
              },
              users_count: { type: "integer" },
              uuid: { type: "string" },
            },
            required: %w[id address agents cancelled_at collectif context created_by deleted_at duration_in_min lieu max_participants_count motif name organisation rdvs_users starts_at status users
                         users_count uuid],
          },
          agent: {
            type: "object",
            properties: {
              id: { type: "integer" },
              email: { type: "string" },
              first_name: { type: "string", nullable: true },
              last_name: { type: "string", nullable: true },
            },
            required: %w[id email first_name last_name],
          },
          user: {
            type: "object",
            nullable: true,
            properties: {
              id: { type: "integer" },
              address: { type: "string", nullable: true },
              address_details: { type: "string", nullable: true },
              affiliation_number: { type: "string", nullable: true },
              bith_date: { type: "string", format: "date", nullable: true },
              bith_name: { type: "string", nullable: true },
              caisse_affiliation: { type: "string", enum: %w[aucun caf msa] },
              case_number: { type: "string", nullable: true },
              created_at: { type: "string" },
              email: { type: "string" },
              family_situation: { type: "string", enum: %w[single in_a_relationship divorced] },
              first_name: { type: "string" },
              invitation_accepted_at: { type: "string", nullable: true },
              invitation_created_at: { type: "string", nullable: true },
              last_name: { type: "string" },
              notify_by_email: { type: "boolean" },
              notify_by_sms: { type: "boolean" },
              number_of_children: { type: "integer" },
              phone_number: { type: "string", nullable: true },
              phone_number_formatted: { type: "string", nullable: true },
              responsible: { type: "object", nullable: true },
              responsible_id: { type: "integer", nullable: true },
              user_profiles: {
                type: "array",
                nullable: true,
                items: { "$ref" => "#/components/schemas/user_profiles" },
              },
            },
            required: %w[id address address_details affiliation_number birth_date birth_name caisse_affiliation case_number created_at email family_situation first_name invitation_accepted_at
                         invitation_created_at last_name notify_by_email notify_by_sms number_of_children phone_number phone_number_formatted responsible responsible_id user_profiles],
          },
          user_profiles: {
            type: "object",
            properties: {
              user: { "$ref" => "#/components/schemas/user" },
              organisation: { "$ref" => "#/components/schemas/organisation" },
              logement: { type: "string", enum: %w[sdf heberge en_accession_propriete proprietaire autre locataire] },
              note: { type: "string", nullable: true },
            },
            required: %w[user organisation logement note],
          },
          organisation: {
            type: "object",
            properties: {
              id: { type: "integer" },
              email: { type: "string", nullable: true },
              name: { type: "string" },
              phone_number: { type: "string", nullable: true },
            },
            required: %w[id email name phone_number],
          },
          lieu: {
            type: "object",
            properties: {
              id: { type: "integer" },
              address: { type: "string" },
              name: { type: "string" },
              organisation_id: { type: "integer" },
              phone_number: { type: "string", nullable: true },
              single_use: { type: "boolean" },
            },
            required: %w[id address name organisation_id phone_number single_use],
          },
          motif: {
            type: "object",
            properties: {
              id: { type: "integer" },
              category: { type: "string", enum: %w[rsa_orientation rsa_accompagnement rsa_orientation_on_phone_platform rsa_cer_signature rsa_insertion_offer rsa_follow_up] },
              deleted_at: { type: "string", nullable: true },
              location_type: { type: "string", enum: %w[public_office phone home] },
              name: { type: "string" },
              organisation_id: { type: "integer" },
              reservable_online: { type: "boolean" },
              service_id: { type: "integer" },
            },
            required: %w[id category deleted_at location_type name organisation_id reservable_online service_id],
          },
          rdvs_user: {
            type: "object",
            properties: {
              send_lifecycle_notifications: { type: "boolean" },
              send_reminder_notification: { type: "boolean" },
              status: { type: "string", enum: %w[unknown waiting seen excused revoked noshow] },
              user: { "$ref" => "#/components/schemas/user" },
            },
            required: %w[send_lifecycle_notifications send_reminder_notification status user],
          },
          meta: {
            type: "object",
            properties: {
              current_page: { type: "integer" },
              next_page: { type: "integer", nullable: true },
              prev_page: { type: "integer", nullable: true },
              total_pages: { type: "integer" },
              total_count: { type: "integer" },
            },
            required: %w[current_page next_page prev_page total_pages total_count],
          },
        },
      },
      tags: [
        {
          name: "RDV",
          description: "Pour manipuler des rendez-vous",
        },
      ],
      servers: [
        {
          url: "https://www.rdv-solidarites.fr",
          description: "Serveur de production",
        },
        {
          url: "https://demo.rdv-solidarites.fr",
          description: "Serveur de démo",
        },
      ],
    },
  }

  # Specify the format of the output Swagger file when running 'rswag:specs:swaggerize'.
  # The swagger_docs configuration option has the filename including format in
  # the key, this may want to be changed to avoid putting yaml in json files.
  # Defaults to json. Accepts ':json' and ':yaml'.
  config.swagger_format = :json
end
