# frozen_string_literal: true

module Rdv::AuthoredConcern
  extend ActiveSupport::Concern

  included do
    has_many :versions_where_event_eq_create,
             -> { where(event: "create") },
             class_name: "PaperTrail::Version",
             as: :item, dependent: :delete_all, inverse_of: :item
  end

  def author
    creation_event = versions_where_event_eq_create.loaded? ? versions_where_event_eq_create.first : versions.where(event: "create").first
    whodunnit = creation_event&.whodunnit
    return nil if whodunnit.blank?

    if whodunnit.starts_with?("[User] ")
      whodunnit.gsub("[User] ", "")
    elsif whodunnit.starts_with?("[Agent] ")
      whodunnit.gsub("[Agent] ", "")
    else
      whodunnit
    end
  end
end
