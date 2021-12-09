# frozen_string_literal: true

module CreneauxHelper
  COLORS = %w[
    color-scheme-bleu
    color-scheme-orange
    color-scheme-green
    color-scheme-pink
    color-scheme-indigo
    color-scheme-turquoise
    color-scheme-yellow
    color-scheme-purple
    color-scheme-lightturquoise
    color-scheme-red
    color-scheme-teal
  ].freeze
  def agent_color(color_index)
    COLORS[color_index || 0 % COLORS.length]
  end
end
