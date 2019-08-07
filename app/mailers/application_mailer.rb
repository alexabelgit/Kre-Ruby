class ApplicationMailer < ActionMailer::Base
  helper :mailer

  include Resque::Mailer
  protected

  def additional_args(category:, **args)
    headers 'X-SMTPAPI' => {
                unique_args: args,
                category: category
            }.to_json
  end
end
