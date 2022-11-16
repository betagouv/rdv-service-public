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
        description: File.read(Rails.root.join("docs/api/v1/description_api.md")),
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
          rdvs: {
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
          agents: {
            type: "object",
            properties: {
              agents: {
                type: "array",
                items: { "$ref" => "#/components/schemas/agent" },
              },
              meta: { "$ref" => "#/components/schemas/meta" },
            },
            required: %w[agents meta],
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
          user_with_root: {
            type: "object",
            properties: {
              user: { "$ref" => "#/components/schemas/user" },
            },
            required: %w[user],
          },
          users: {
            type: "object",
            properties: {
              users: {
                type: "array",
                items: { "$ref" => "#/components/schemas/user" },
              },
              meta: { "$ref" => "#/components/schemas/meta" },
            },
            required: %w[users meta],
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
              caisse_affiliation: { type: "string", enum: %w[aucun caf msa], nullable: true },
              case_number: { type: "string", nullable: true },
              created_at: { type: "string" },
              email: { type: "string", nullable: true },
              family_situation: { type: "string", enum: %w[single in_a_relationship divorced], nullable: true },
              first_name: { type: "string" },
              invitation_accepted_at: { type: "string", nullable: true },
              invitation_created_at: { type: "string", nullable: true },
              last_name: { type: "string" },
              notify_by_email: { type: "boolean" },
              notify_by_sms: { type: "boolean" },
              number_of_children: { type: "integer", nullable: true },
              phone_number: { type: "string", nullable: true },
              phone_number_formatted: { type: "string", nullable: true },
              responsible: { type: "object", nullable: true },
              responsible_id: { type: "integer", nullable: true },
              user_profiles: {
                type: "array",
                nullable: true,
                items: { "$ref" => "#/components/schemas/user_profile" },
              },
            },
            required: %w[id address address_details affiliation_number birth_date birth_name case_number created_at first_name invitation_accepted_at
                         invitation_created_at last_name notify_by_email notify_by_sms phone_number phone_number_formatted responsible responsible_id user_profiles],
          },
          user_profile_with_root: {
            type: "object",
            properties: {
              user_profile: { "$ref" => "#/components/schemas/user_profile" },
            },
            required: %w[user_profile],
          },
          user_profile: {
            type: "object",
            properties: {
              user: { "$ref" => "#/components/schemas/user" },
              organisation: { "$ref" => "#/components/schemas/organisation" },
              logement: { type: "string", enum: %w[sdf heberge en_accession_propriete proprietaire autre locataire], nullable: true },
              notes: { type: "string", nullable: true },
            },
            required: %w[organisation logement notes],
          },
          organisations: {
            type: "object",
            properties: {
              organisations: {
                type: "array",
                items: { "$ref" => "#/components/schemas/organisation" },
              },
              meta: { "$ref" => "#/components/schemas/meta" },
            },
            required: %w[organisations meta],
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
          absence_with_root: {
            type: "object",
            properties: {
              absence: { "$ref" => "#/components/schemas/absence" },
            },
            required: %w[absence],
          },
          absences: {
            type: "object",
            properties: {
              absences: {
                type: "array",
                items: { "$ref" => "#/components/schemas/absence" },
              },
              meta: { "$ref" => "#/components/schemas/meta" },
            },
            required: %w[absences meta],
          },
          absence: {
            type: "object",
            properties: {
              id: { type: "integer" },
              ical_uid: { type: "string" },
              title: { type: "string" },
              first_day: { type: "string", format: "date" },
              end_day: { type: "string", format: "date" },
              start_time: { type: "string" },
              end_time: { type: "string" },
              agent: { "$ref" => "#/components/schemas/agent", nullable: true },
              organisation: { "$ref" => "#/components/schemas/organisation" },
            },
            required: %w[id ical_uid title first_day end_day start_time end_time agent organisation],
          },
          organizations: {
            type: "object",
            properties: {
              organizations: {
                type: "array",
                items: { "$ref" => "#/components/schemas/organization" },
              },
              meta: { "$ref" => "#/components/schemas/meta" },
            },
            required: %w[organizations meta],
          },
          organization: {
            type: "object",
            properties: {
              id: { type: "integer" },
              label: { type: "string" },
              group_id: { type: "integer" },
              phone_number: { type: "string", nullable: true },
              email: { type: "string", nullable: true },
              website: { type: "string", nullable: true },
              public_link: { type: "string" },
            },
            required: %w[id label group_id public_link],
          },
          invitation: {
            type: "object",
            properties: {
              invitation_url: { type: "string" },
              invitation_token: { type: "string" },
            },
            required: %w[invitation_url invitation_token],
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
          motifs: {
            type: "object",
            properties: {
              motifs: {
                type: "array",
                items: { "$ref" => "#/components/schemas/motif" },
              },
              meta: { "$ref" => "#/components/schemas/meta" },
            },
            required: %w[motifs meta],
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
          errors_generic: {
            type: "object",
          },
          error_too_many_request: {
            type: "object",
            properties: {
              errors: {
                type: "array",
                items: { type: "string" },
              },
            },
            required: %w[errors],
          },
          error_authentication: {
            type: "object",
            properties: {
              errors: {
                type: "array",
                items: { type: "string" },
              },
            },
            required: %w[errors],
          },
          error_unauthorized: {
            type: "object",
            properties: {
              errors: {
                type: "array",
                items: {
                  type: "object",
                  properties: {
                    base: { type: "string" },
                  },
                  required: %w[base],
                },
              },
            },
            required: %w[errors],
          },
          error_not_found: {
            type: "object",
            properties: {
              not_found: { type: "string" },
            },
            required: %w[not_found],
          },
          error_unprocessable_entity: {
            type: "object",
            properties: {
              success: { type: "boolean" },
              errors: {
                type: "object",
              },
              error_messages: {
                type: "array",
                items: { type: "string" },
              },
            },
            required: %w[success errors error_messages],
          },
        },
      },
      tags: [
        {
          name: "Invitation",
          description: "Pour manipuler des usager·ères via leur jeton d'invitation",
        },
        {
          name: "User",
          description: "Pour manipuler des usager·ères",
        },
        {
          name: "Agent",
          description: "Pour manipuler des agent·es",
        },
        {
          name: "RDV",
          description: "Pour manipuler des rendez-vous",
        },
        {
          name: "Organisation",
          description: "Pour manipuler des organisations",
        },
        {
          name: "PublicLink",
          description: "Pour manipuler des liens publics de recherche",
        },
      ],
      servers: [
        {
          url: "http://localhost:3000/",
          description: "Serveur de développement",
        },
        {
          url: "https://demo.rdv-solidarites.fr",
          description: "Serveur de démo",
        },
        {
          url: "https://www.rdv-solidarites.fr",
          description: "Serveur de production",
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
