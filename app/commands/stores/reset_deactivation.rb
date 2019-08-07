module Stores
  class ResetDeactivation < ApplicationCommand
    object :store

    def execute
      store.update deactivated_at: nil

      store.update_settings :billing, miss_you_email_sent: false,
                                      store_deleted_email_sent: false
    end
  end
end
