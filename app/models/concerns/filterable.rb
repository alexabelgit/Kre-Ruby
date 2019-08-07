module Filterable
  extend ActiveSupport::Concern

  module ClassMethods

    @unfiltered = {}

    def filtered(current_store:, term: '*', filter_params: {}, filter_gte_params: {},  sort: {}, unfilter_params: [], page: nil, per_page: nil, limit: nil, ignore_under: 1)

      search_term = term.blank? ? '*' : term

      where_clause = { store_id: current_store.id }
      filter_params.each  do |key, val|
        if val.present?
          value = val.is_a?(Symbol) ? val.to_s : val
          where_clause.merge!({ key => value })
        end
      end

      filter_gte_params.each  do |key, val|
        if val.present?
          value = {gte: val.is_a?(Symbol) ? val.to_s : val}
          where_clause.merge!({ key => value })
        end
      end

      where_clause.symbolize_keys!

      unfilter_params.each do |unfilter_param|
        if unfilter_param == :term
          @unfiltered[unfilter_param] = self.search('*', where: where_clause)
        else
          @unfiltered[unfilter_param] = self.search(search_term, where: where_clause.except(unfilter_param.key))
        end
      end

      if search_term.length <= ignore_under && search_term != '*'
        res = current_store.send(self.name.pluralize.underscore).none.paginate(page: page, per_page: per_page || 10)
      elsif search_term == '*' && filter_params == {} && filter_gte_params == {} && (sort == {} ||
          ((sort.respond_to?(:keys) && self.respond_to?(sort.keys.first.to_s)) || (!sort.respond_to?(:keys) && self.respond_to?(sort.to_s))))

        res = current_store.send(self.name.pluralize.underscore)

        if sort.present?
          if sort.respond_to?(:keys)
            sort_key   = sort.keys.first
            sort_value = sort[sort_key]
            sort_mode  = {sort_key => sort_value}
            res        = res.send(sort_key.to_s, sort_value)
          else
            sort_mode = sort.to_sym
            res       = res.send(sort.to_s)
          end
        end

        res = res.paginate(page: page, per_page: per_page || 10)

      else

        if sort.blank?
          sort = {}
        elsif sort.respond_to?(:keys)
          sort_key   = sort.keys.first
          sort_value = sort[sort_key]
          sort       = { sort_key => sort_value }
          sort_mode  = sort
          sort       = { self.sort_mapper[sort_key.to_sym].keys.first => { order: sort_value.to_sym, unmapped_type: :long } }.symbolize_keys!
        else
          sort_mode = sort.to_sym
          sort = self.sort_mapper[sort.to_sym]
        end
        sort.merge!({_score: :desc})

        res = self.search search_term, fields: self.search_fields, match: :word_start,
                          where: where_clause, page: page, per_page: per_page, order: sort, limit: limit,
                          misspellings: { below: 5, prefix_length: 4 }, highlight: { tag: '<mark class="hc-highlight">' }
      end
      
      res.define_singleton_method(:search_term)  { term          }
      res.define_singleton_method(:filter_value) { filter_gte_params.merge filter_params }
      res.define_singleton_method(:sort_mode)    { sort_mode     }
      res
    end

    def define_filterable_methods!(search_term:, filter_value:, sort_mode:)
      self.define_singleton_method(:search_term)  { search_term  }
      self.define_singleton_method(:filter_value) { filter_value }
      self.define_singleton_method(:sort_mode)    { sort_mode    }
      self
    end

    def unfiltered(key)
      @unfiltered.has_key?(key) ? @unfiltered[key] : []
    end
  end

  def get_highlights(method, static = nil)
    res = static.present? ? static : self.send(method)
    if self.respond_to?(:search_highlights)
      highlights = self.search_highlights[method]
      if highlights.present?
        sub_highlights = highlights.gsub('<mark class="hc-highlight">', '').gsub('</mark>', '')
        res            = res.gsub(sub_highlights, highlights).html_safe if res.include?(sub_highlights)
      end
    end
    res
  end

  def has_highlights?(method)
    self.respond_to?(:search_highlights) && self.search_highlights[method].present?
  end

end
