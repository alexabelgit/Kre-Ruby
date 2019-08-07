module WillPaginate
  module ActionView
    def will_paginate(collection = nil, options = {})
      options, collection = collection, nil if collection.is_a? Hash
      collection ||= infer_collection_from_controller

      options = options.symbolize_keys
      options[:renderer] ||= HCLinkRenderer
      options[:class] ||= ""
      if options[:class].include? "hc-paging--modern"
        options[:previous_label] ||= '&laquo;'
        options[:next_label] ||= '&raquo;'
      end
      options[:link_separator] ||= ''

      super(collection, options)
    end
  end
end