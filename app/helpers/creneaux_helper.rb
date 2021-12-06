# frozen_string_literal: true

module CreneauxHelper
  COLORS = %w[
    color-scheme-bleu
    color-scheme-turquoise
    color-scheme-indigo
    color-scheme-purple
    color-scheme-pink
    color-scheme-yellow
    color-scheme-red
    color-scheme-orange
    color-scheme-green
    color-scheme-teal
    color-scheme-lightturquoise
  ].freeze
  def agent_color(color_index)
    COLORS[color_index % COLORS.length]
  end
end
