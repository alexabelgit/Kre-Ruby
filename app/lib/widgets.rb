module Widgets
  LIST = [:product_rating,
          :product_summary,
          :product_tabs,
          :sidebar,
          :review_slider,
          :review_journal,
          :reviews_facebook_tab].freeze

  class << self
    def exists?(name)
      name.is_a?(String) && (name.split(',').map(&:to_sym) - LIST).size <= 0
    end
  end
end
