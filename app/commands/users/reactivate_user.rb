module Users
  class ReactivateUser < ApplicationCommand
    object :user

    def execute
      return unless user.deleted?

      user.update_attribute :deleted_at, nil
      store = user.store

      if store.present?
        reactivate_store store
        ImportProductsWorker.perform_async(store.id)
      end
    end

    private

    def reactivate_store(store)
      store.active!
      store.storefront_active!

      ScheduledJobsCleaner.run(DeleteImagesJob, store.id)
      ScheduledJobsCleaner.run(DeleteImagesWorker, store.id)
      ScheduledJobsCleaner.run(AnonymizeCustomersWorker, store.id)
    end
  end
end
