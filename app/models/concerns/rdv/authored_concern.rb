# frozen_string_literal: true

module Rdv::AuthoredConcern
  extend ActiveSupport::Concern

  def author
    whodunnit = versions.where(event: "create").first&.whodunnit
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
