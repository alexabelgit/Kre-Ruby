if ENV['SEND_ALL_EMAILS_TO_SANDBOX']
  ActionMailer::Base.register_interceptor(SandboxEmailInterceptor)
end
