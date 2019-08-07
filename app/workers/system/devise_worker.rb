class DeviseWorker
  include Sidekiq::Worker
  sidekiq_options queue: :mailers

  def perform(devise_mailer, method, user_id, *args)
    user = User.find(user_id)
    devise_mailer = devise_mailer.constantize if devise_mailer.is_a?(String)
    devise_mailer.send(method, user, *args).deliver_now
  end
end
