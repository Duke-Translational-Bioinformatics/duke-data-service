class UserFilter
  def initialize(params = nil)
    unless params.nil?
      if params[:full_name_contains] && !params[:full_name_contains].empty?
        @full_name_contains = params[:full_name_contains]
      end

      if params[:first_name_begins_with] && !params[:first_name_begins_with].empty?
        @first_name_begins_with = params[:first_name_begins_with]
      end

      if params[:last_name_begins_with] && !params[:last_name_begins_with].empty?
        @last_name_begins_with = params[:last_name_begins_with]
      end
    end
  end

  def query(relation)
    unless @full_name_contains.nil?
      relation = relation.where(
        "lower(display_name) like ?", "%#{ @full_name_contains.downcase }%"
      )
    end

    unless @first_name_begins_with.nil?
      relation = relation.where(
        "lower(first_name) like ?", "#{ @first_name_begins_with.downcase }%"
      )
    end

    unless @last_name_begins_with.nil?
      relation = relation.where(
        "lower(last_name) like ?", "#{ @last_name_begins_with.downcase }%"
      )
    end
    relation
  end
end
