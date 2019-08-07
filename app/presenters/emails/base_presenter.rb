module Emails
  class BasePresenter
    attr_reader :store, :view, :subscription

    def initialize(store, view = ActionView::Base.new)
      @store = store
      @subscription   = store.active_subscription
      @view = view
    end

    def user_name
      store.user.first_name
    end

    def user_email
      store.user.email
    end
  end
end