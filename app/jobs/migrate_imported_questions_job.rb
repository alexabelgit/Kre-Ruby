class MigrateImportedQuestionsJob < ApplicationJob
  queue_as :default

  ### SIDEKIQED

  def perform(store_id)
    store = Store.find_by_id(store_id)
    return unless store.present?

    store.imported_questions.where(marked_for_deletion: true).destroy_all
    Comment.skip_callback(:commit, :after, :reindex_children)
    Searchkick.callbacks(false) do
      store.imported_questions.where(marked_for_deletion: false).order(created_at: :asc).each do |imported_question|

        question = Question.create(customer:     imported_question.customer,
                                   product:      imported_question.product,
                                   body:         imported_question.body,
                                   status:       imported_question.status,
                                   submitted_at: imported_question.submitted_at)
        question.verified_by_merchant! if imported_question.verified?

        if question.valid? && imported_question.answer.present?
          Comment.create(commentable:  question,
                         body:         imported_question.answer,
                         user:         store.user,
                         display_name: store.settings(:agents).default_name)
        end

        imported_question.destroy
      end
    end
    Comment.set_callback(:commit, :after, :reindex_children)
    store.reindex_children

    store.settings(:background_workers).update_attributes(migrating_imported_questions: false)
  end
end
