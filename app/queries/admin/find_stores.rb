module Admin
  class FindStores
    attr_accessor :initial_scope

    def initialize(initial_scope = Store.all)
      @initial_scope = initial_scope
    end

    def call(params)
      scoped = joins(initial_scope, params[:joins])
      scoped = search(scoped, params[:search_term])
      scoped = filter(scoped, params)
      scoped = sort(scoped, params[:sort_by], params[:sort_direction])
      scoped = paginate(scoped, params[:page], params[:per_page])
      scoped = scoped.includes(:setting_objects, :ecommerce_platform, :user)
      scoped
    end

    private

    def joins(scoped, relations)
      return scoped unless relations
      scoped.joins(relations)
    end

    def search(scoped, term)
      return scoped unless term

      query = <<-SQL
        lower(stores.name) LIKE lower('%#{term}%') OR
        lower(stores.url) LIKE lower('%#{term}%') OR
        stores.id_from_provider = '#{term}' OR
        lower(users.first_name) LIKE lower('%#{term}%') OR
        lower(users.last_name) LIKE lower('%#{term}%') OR
        lower(users.email) LIKE lower('%#{term}%')
        SQL
      scoped.where query
    end

    def filter(scoped, params)
      scoped = scoped.storefront_active if params[:storefront_active].to_b
      scoped = scoped.active            if params[:backend_active].to_b
      scoped
    end

    def sort(scoped, sort_by, sort_direction)
      sort_by ||= :created_at
      sort_direction ||= :desc
      scoped.order(sort_by => sort_direction)
    end

    def paginate(scoped, page, per_page)
      page ||= 1
      per_page ||= 10
      scoped.paginate(page: page, per_page: per_page)
    end
  end
end
