module Integrations::ShopifyHelper
  def remaining_snippets_list(store)
    snippets = Shopify::Utils.auto_remove_status_list(store)
    content_tag :div do
      content_tag(:p, "Here are the snippets we could not remove:") +
      content_tag(:ul) do
        snippets.each do |snippet|
          concat %Q(
            <li>
              <strong>#{ snippet["snippet"] }</strong> from file
              <strong>#{ snippet["file"] }</strong> in theme
              <strong>#{ snippet["theme"] }</strong>
            </li>
          ).html_safe
        end
      end
    end
  end
end
