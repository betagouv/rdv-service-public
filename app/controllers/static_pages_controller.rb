# frozen_string_literal: true

require "redcarpet"
require "redcarpet/render_strip"

class StaticPagesController < ApplicationController
  def disclaimer; end

  def terms; end

  def mds; end

  def changelog
    fichier = File.join(Rails.root, "CHANGELOG.md")
    renderer = Redcarpet::Render::HTML.new(hard_wrap: true)
    markdown = Redcarpet::Markdown.new(renderer, {})
    contenue = markdown.render(File.read(fichier)).to_s
    @html_changelog = contenue.html_safe
  end
end
