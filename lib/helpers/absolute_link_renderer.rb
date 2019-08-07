# TODO about requires: https://stackoverflow.com/a/11089418/1950438 extend decision to other similar places
require 'will_paginate/view_helpers/link_renderer'
require 'will_paginate/view_helpers/action_view'

class HCLinkRenderer < WillPaginate::ActionView::LinkRenderer
  ELLIPSIS = '&hellip;'

  def to_html
    list_items = pagination.map do |item|
      case item
        when Integer
          page_number(item)
        else
          send(item)
      end
    end.join(@options[:link_separator])

    list_wrapper = tag :ul, list_items, class: @options[:class].to_s
    tag :div, list_wrapper
  end

  def container_attributes
    super.except(*[:link_options])
  end

  protected

  def page_number(page)
    link_options = @options[:link_options] || {}

    if page == current_page
      tag :li, tag(:span, page, class: 'page-link'), class: 'page-item active'
    else
      link_options.merge! class: 'page-link', rel: rel_value(page)
      tag :li, link(page, page, link_options), class: 'page-item'
    end
  end

  def previous_or_next_page(page, text, classname)
    link_options = @options[:link_options] || {}

    if page
      link_wrapper = link(text, page, link_options.merge(class: 'page-link'))
      tag :li, link_wrapper, class: 'page-item'
    else
      span_wrapper = tag(:span, text, class: 'page-link')
      tag :li, span_wrapper, class: 'page-item disabled'
    end
  end

  def gap
    tag :li, tag(:i, ELLIPSIS, class: 'page-link'), class: 'page-item disabled'
  end

  def previous_page
    num = @collection.current_page > 1 && @collection.current_page - 1
    previous_or_next_page num, @options[:previous_label], 'previous'
  end

  def next_page
    num = @collection.current_page < @collection.total_pages && @collection.current_page + 1
    previous_or_next_page num, @options[:next_label], 'next'
  end
end


class HCAbsoluteLinkRenderer < HCLinkRenderer
  def prepare(collection, options, template)
    @base_link_url = options.delete :base_link_url
    @base_link_url = reject_param(@base_link_url, :page)
    @base_link_url_has_qs = @base_link_url.index('?') != nil if @base_link_url
    super
  end

  def link(text, target, attributes = {})
    attributes['data-remote'] = true
    super
  end

  protected
  def url(page)
    if @base_link_url.blank?
      super
    else
      @base_url_params ||= begin
        merge_optional_params(default_url_params)
      end

      url_params = @base_url_params.dup
      add_current_page_param(url_params, page)

      query_s = []
      url_params.each_pair {|key,val| query_s.push("#{key}=#{val}")}

      if query_s.size > 0
        @base_link_url + (@base_link_url_has_qs ? '&' : '?') + query_s.join('&')
      else
        @base_link_url
      end
    end
  end

  private

  def reject_param(url, param_to_reject)
    param_to_reject = param_to_reject.to_s
    # Regex from RFC3986
    url_regex = %r"^(([^:/?#]+):)?(//([^/?#]*))?([^?#]*)(\?([^#]*))?(#(.*))?$"
    raise "Not a url: #{url}" unless url =~ url_regex
    scheme_plus_punctuation = $1
    authority_with_punctuation = $3
    path = $5
    query = $7
    fragment = $9
    query = query.split('&').reject do |param|
      param_name = param.split(/[=;]/).first
      param_name == param_to_reject
    end.join('&') unless query.blank?
    [scheme_plus_punctuation, authority_with_punctuation, path, '?', query, fragment].join
  end
end
