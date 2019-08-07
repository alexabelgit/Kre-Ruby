class SandboxEmailInterceptor

  SANDBOX_EMAIL = (ENV['SANDBOX_EMAIL'] || "helpfulcrowd.devs+stg@gmail.com").freeze

  def self.delivering_email(message)
    message.to = SANDBOX_EMAIL
  end
end
