class OutlookConfig < ApplicationRecord
  has_paper_trail

  normalizes :microsoft_graph_token, :microsoft_graph_refresh_token, with: ->(str) { str.presence }

  encrypts :microsoft_graph_token
  encrypts :microsoft_graph_refresh_token

  belongs_to :agent
end
