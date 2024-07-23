class Admin::EditRdvForm
  include ActiveModel::Model
  include Admin::RdvFormConcern

  attr_accessor :agent_context

  def initialize(rdv, agent_context)
    @rdv = rdv
    @agent_context = agent_context
  end

  def update(**rdv_attributes)
    rdv_attributes = cleanup_duplicate_participations(rdv_attributes)

    @rdv.assign_attributes(rdv_attributes)

    if valid?
      @rdv.save_and_notify(agent_context.agent)
    else
      false
    end
  end

  private

  def cleanup_duplicate_participations(rdv_attributes)
    rdv_attributes.with_indifferent_access["participations_attributes"].map do |_index, attributes|
      existing_participation = @rdv.participations.find_by(user_id: attributes["user_id"])

      attributes["id"] = existing_participation&.id
    end.to_h
  end
end
