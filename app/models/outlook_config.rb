class OutlookConfig < ApplicationRecord
  has_paper_trail

  encrypts :microsoft_graph_token
  encrypts :refresh_microsoft_graph_token

  belongs_to :agent

  def connected?
    microsoft_graph_token.present?
  end
end
