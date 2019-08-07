
module Stores
  module Admin
    class ResetImportedReviews < ApplicationCommand
      object :store
  
      def execute
          Review.destroy store.reviews.where(source: 'imported').pluck(:id)
      end
    end
  end
end
  