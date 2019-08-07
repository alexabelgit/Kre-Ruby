class SyncStoresWithIntercomJob < ApplicationJob
  queue_as :low

  ### SIDEKIQED

  def perform
    Store.find_each do |store|
      Integrations::Intercom.sync store
    end
  end
end
