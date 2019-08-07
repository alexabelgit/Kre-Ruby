module MailerHelper

  def blockquote(content)
    content_tag(:blockquote, content)
  end

  def span_quote(content)
    content_tag(:span, content, class: 'span-qoute')
  end

  def strong(content)
    content_tag(:strong, content)
  end

  def call_to_action(text, url)
    content_tag(:div, class: 'call-to-action') do
      content_tag(:a, text, href: url, class: 'hc-primary-button')
    end
  end

end
