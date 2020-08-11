class FindDuplicateUsersSuggestionsService < BaseService
  SCORE_THRESHOLD = 0.8

  def initialize(organisation, slice: nil, hydrate_users: false, users_scope: nil)
    @organisation = organisation
    @hydrate_users = hydrate_users
    @slice = slice
    @users_scope = users_scope || User.all
  end

  def perform
    OpenStruct.new(hits: hits, combinations_count: all_combinations.count)
  end

  protected

  def hits
    raw_hits.map { @hydrate_users ? hydrate_hit(_1) : _1 }
  end

  def raw_hits
    @raw_hits ||= combinations
      .map { compute_raw_hits(_1, _2) }
      .compact
      .flatten(1)
      .sort_by(&:score)
      .reverse
  end

  def combinations
    @combinations ||= \
      if @slice.present?
        all_combinations.to_a[(@slice.first)..(@slice.second)]
      else
        all_combinations
      end
  end

  def all_combinations
    @all_combinations ||= users_names.combination(2)
  end

  def compute_raw_hits(name1, name2)
    score = 1 - (
      DamerauLevenshtein.distance(name1, name2).to_f / [name1.length, name2.length].max
    )
    return nil if score < SCORE_THRESHOLD

    (user_ids_by_names[name1] + user_ids_by_names[name2])
      .sort.combination(2).map { OpenStruct.new(score: score, user_ids: _1) }
  end

  def users
    @users ||= @organisation.users.active.order(:id).select(:id, :first_name, :last_name)
  end

  def user_ids_by_names
    @user_ids_by_names ||= users
      .group_by { format_user_name(_1) }
      .map { [_1, _2.pluck(:id)] }
      .to_h
  end

  def format_user_name(user)
    "#{user.first_name} #{user.last_name}"
      .parameterize
      .gsub(/(monsieur\-|madame\-|mr\-|mme\-|m\-|mlle\-)/, "")
      .gsub("-", " ")
      .strip
  end

  def users_names
    @users_names ||= user_ids_by_names.keys
  end

  def hydrate_hit(hit)
    OpenStruct.new(users: hit.user_ids.map { hits_users_by_ids[_1] }, **hit.to_h)
  end

  def hits_users_by_ids
    @hits_users_by_ids ||= @users_scope
      .where(id: raw_hits.map(&:user_ids).flatten)
      .select(:id, :first_name, :last_name, :birth_name)
      .to_a
      .group_by(&:id)
      .transform_values { _1.first } # group_by returns arrays but we expect one
      .to_h
  end
end
