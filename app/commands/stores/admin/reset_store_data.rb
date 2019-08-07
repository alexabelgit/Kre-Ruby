module Stores
  module Admin
    class ResetStoreData < ApplicationCommand
      object :store
    
      def execute
        Review.destroy store.reviews.pluck(:id)
        Question.destroy store.questions.pluck(:id)
      end
    end
  end
end
  