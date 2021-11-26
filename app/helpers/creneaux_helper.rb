# frozen_string_literal: true

module CreneauxHelper
  COLORS = %w[
    color-scheme-bleu
    color-scheme-red
    color-scheme-green
    color-scheme-yellow
    color-scheme-pink
    color-scheme-purple
    color-scheme-grey
    color-scheme-beige
    color-scheme-apple-green
    color-scheme-burgundy
    color-scheme-duck-green
    color-scheme-light-blue
    color-scheme-light-grey
    color-scheme-light-purple
    color-scheme-strong-green
    color-scheme-strong-blue
    color-scheme-strong-grey
    color-scheme-strong-red
    color-scheme-strong-pink
    color-scheme-strong-purple
  ].freeze
  def agent_color(color_index)
    COLORS[color_index % COLORS.length]
  end
end
