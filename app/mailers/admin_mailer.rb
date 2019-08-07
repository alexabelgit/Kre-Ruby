class AdminMailer < ApplicationMailer

  FROM_SUPPORT = "HelpfulCrowd Support <support@helpfulcrowd.com>".freeze

  default from: FROM_SUPPORT
  layout 'mailer/admin'


  def reports(email_address, reports)
    reports.each do |report|
      report[:variables].each do |variable|
        self.instance_variable_set(:"@#{variable.first.first}", variable.first.last)
      end
      xlsx = render_to_string layout: false, handlers: [:axlsx], formats: [:xlsx], template: report[:template]
      attachment = Base64.encode64(xlsx)
      attachments["#{report[:template].split('/').last}.xlsx"] = {mime_type: Mime[:xlsx], content: attachment, encoding: 'base64'}
    end

    mail(to: email_address, subject: "Admin Reports From #{ENV['WEB_APP_HOST']}")
  end


end
