class AgentTerritorialAccessRight < ApplicationRecord
  self.ignored_columns = ["allow_to_download_metrics"]

  # Mixins
  has_paper_trail

  # Relations
  belongs_to :agent
  belongs_to :territory
end
