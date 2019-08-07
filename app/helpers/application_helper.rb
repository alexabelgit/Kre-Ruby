# coding: utf-8
module ApplicationHelper

  STATUS_ICONS = {
    rqa: {
      pending:    'exclamation-circle',
      published:  'check-circle',
      archived:   'info-circle',
      suppressed: 'exclamation-triangle'
    },
    review_request: {
      scheduled:  'clock-o',
      pending:    'clock-o',
      incomplete: 'info-circle',
      complete:   'check-circle',
      cancelled:  'times-circle',
      on_hold:    'pause-circle-o'
    },
    coupon_code: {
      pending:    'clock-o',
      used:       'check-circle'
    },
    discount_coupon: {
      true:       'check-circle',
      false:      'times-circle'
    },
    promotion: {
      true:       'check-circle',
      false:      'times-circle'
    }
  }

  def filter_select(name, filter_object, key, collection, prompt = "All #{ name.downcase }", title_method = :title, id_method = :id, html_options: {})
    filtered_collection = filter_select_collection(collection, key, title_method, id_method, prompt)
    options = options_for_select(filtered_collection, filter_object[key].to_s)
    select_tag name,
               options,
               html_options.merge(data: { role: 'filter'})
  end

  def filter_select_collection(collection, key, title_method = :title, id_method = :id, prompt = 'all')
    res = []
    res << [prompt, '', { 'data-url' => filter_link(without_keys: [key]) }] unless prompt.blank?
    res + collection.map do|c|
      data_url = filter_link(key.to_sym => c[id_method], without_keys: [:page])
      [
        c[title_method],
        c[id_method],
        { 'data-url' => data_url }
      ]
    end
  end

  def filter_link(*params, **named_params)
    full_params = request.query_parameters
    params.each do |param|
      full_params = full_params.merge(param)
    end
    without_keys = []
    without_keys = named_params[:without_keys] if named_params[:without_keys].present?
    without_keys.each do |without_key|
      full_params = full_params.except(without_key)
    end
    named_params = named_params.except(:without_keys)
    full_params = full_params.merge(named_params)

    URI.encode("#{request.path}?#{full_params.map{|key, value| "#{key}=#{value}"}.join('&')}")
  end

  def humane_date(date, skip_time_tag: false)
    date = date.to_date

    if skip_time_tag
      l(date, format: :long)
    else
      time_tag date do
        l(date, format: :long)
      end
    end
  end

  def humane_datetime(datetime, hide_time: false, skip_time_tag: false)
    if skip_time_tag
      # Don't care about hide_time because otherwise only date will be
      # available. Use `humane_date` if you don't need to show time
      l(datetime, format: :long)
    else
      time_tag datetime, title: datetime do
        if hide_time
          l(datetime.to_date, format: :long)
        else
          l(datetime, format: :long)
        end
      end
    end
  end

  def friendly_rating(value)
    value.zero? ? t('helpers.friendly_rating') : value
  end

  def stars_based_on(rating, markup = 'default', size = 'lg')
    content_tag(:span, class: "hc-stars") do
      rating.to_i.times do
        if markup == 'default'
          concat hc_icon "star #{size}"
        elsif markup == 'lite'
          concat '★'
        end
      end

      if rating % 1 != 0
        if markup == 'default'
          concat hc_icon "star-half #{size}"
        elsif markup == 'lite'
          concat (rating - rating.to_i >= 0.5 ? '★' : '☆')
        end
      end

      (5 - rating).to_i.times do
        if markup == 'default'
          concat hc_icon "star-o #{size}"
        elsif markup == 'lite'
          concat '☆'
        end
      end
    end
  end

  def stars_and_rating(rating)
    content_tag :span, class: 'white-space__nowrap' do
      concat stars_based_on(rating)
      concat ' '
      concat content_tag(:span, friendly_rating(rating))
    end
  end

  def sort_param(sort_mode, base)
    direction = :asc.to_s
    direction = :desc.to_s if sort_mode[base.to_s] == :asc.to_s
    direction = nil if sort_mode[base.to_s] == :desc.to_s
    direction.present? ? {"#{base}" => direction} : nil
  end

  def sort_icon(sort_mode, base)
    hc_icon "sort#{ '-' + sort_mode[base.to_s] if sort_mode[base.to_s].present? }"
  end

  def spinner_icon(content: nil)
    hc_icon 'hc-spinner spin'
  end

  def tip(value, margin: true, type: 'info', icon: 'info-circle')
    content_tag(:p, class: "hc-tip #{ type } #{ 'margin__0' unless margin }") do
      if icon
        concat hc_icon icon
        concat ' '
      end
      concat value.html_safe
    end
  end

  def form_hint(value)
    tip     value,
    icon:   false,
    margin: false,
    type:   'pale'
  end

  def card(margin: true, &block)
    content = capture(&block)
    content_tag(:div, class: "hc-card #{ 'margin-bottom__md' if margin }") do
      content
    end
  end

  def options_for_time_zone_select(selected = false)
    options_for_select(TZInfo::Timezone.all.map { |tz| ["#{ tz.identifier } (GMT #{ tz.current_period.utc_total_offset.seconds_to_gmt_dif })", tz.identifier] }, selected.present? ? selected : nil)
  end

  def progress_bar(progress, color: nil, mock_min_value: false, display_percents: false)
    modifiers =  []
    modifiers << "hc-progress-bar--#{color.to_s}"  if color
    modifiers << "hc-progress-bar--mock_min_value" if mock_min_value
    modifiers =  modifiers.join(' ')
    text_class = display_percents ? 'hc-progress_bar__percents' : 'hide-unless-screen-reader'

    content_tag(:div, class: "hc-progress-bar #{modifiers}") do
      content_tag(:div, class: "hc-progress-bar__current-progress", style: "width: #{ progress }%;") do
        content_tag(:span, "#{ progress }%", class: text_class)
      end
    end
  end

  def store_description(label: 'Verified', description: 'Authored by a verified user', item_class: '')
    content_tag(:span, "from #{label}", class: 'hc-color__pale', title: description)
  end

  def verified_icon(item_class: '')
    # The icon contains multiple shapes of different colors stacked. For this we have multiple paths in the SVG hence it's not written in icons.rb file and defined separately here.
    item_class = "#{item_class} hc-verified-icon hc-icon hc-icon--justified"
    content_tag :svg, class: item_class, viewBox: "0 0 1792 1792" do
      concat(content_tag(:g) do
        concat content_tag(:path, "", d: "M1005.41,4.144c-224.627,171.3 -492.998,275.965 -774.288,301.972l0,748.846c0,630.492 774.288,940.207 774.288,940.207c0,0 774.287,-309.715 774.287,-940.207l0,-748.846c-281.29,-26.007 -549.661,-130.672 -774.287,-301.972Z", style: "fill:#00cd67; fill-rule:nonzero;", class: "hc-verified-icon__shield")
        concat content_tag(:path, "", d: "M1005.41,1220.88l246.666,132.735c33.183,17.698 55.306,0 48.669,-35.396l-47.563,-275.425l200.208,-194.679c27.653,-26.546 18.804,-51.987 -18.804,-57.518l-276.531,-38.714l-122.78,-251.09c-16.592,-34.29 -43.139,-34.29 -59.731,0l-122.78,251.09l-276.53,38.714c-37.609,0 -46.458,30.972 -18.805,57.518l200.208,194.679l-47.563,275.425c-6.636,37.608 15.486,53.094 48.67,35.396l246.666,-132.735Z", style: "fill:#fff;")
      end)
    end
  end


  def hc_tooltip(text, args = {})
    unless text.blank?
      position      = args[:position]       || 'left'
      html_class    = args[:class]          || nil
      min_width     = args[:min_width]      || '200px'
      max_width     = args[:max_width]      || '250px'
      text_align    = args[:text_align]     || 'left'

      html_class = "hc-tooltip__content hc-tooltip__#{position} #{html_class}"
      html_style = "min-width: #{min_width}; max-width: #{max_width}; text-align: #{text_align};"
      # html_class  = '#{html_class} .hc-tooltip'

      content_tag(:div, class: html_class, style: html_style) do
        concat(content_tag(:span) do
          concat text
        end)
        concat content_tag(:i)
      end
    end
  end

  def author_of_(item)
    # TODO this switch will need to be updated when we allow comments from customers
    logo_enabled = item.store.logo_visible?
    avatar_enabled = item.store.avatar_visible?
    case item.class.name.downcase
    when 'comment'
      display_name = @store.settings(:agents).default_name.blank? ? item.display_name : @store.settings(:agents).default_name
      label       = t('verified.agent.label', store: item.store.name)
      description = t('verified.agent.description', author: display_name, store: item.store.name)
    when 'review', 'importedreview', 'question', 'importedquestion'
      display_name = item.display_name
      label       = ""
      description = t('verified.customer.label', author: display_name)
    end
    content_tag(:div, class: 'hc-author') do
      concat(content_tag(:div, class: "hc-author__avatar") do
        if item.is_a?(Comment)
          avatar_logo(item) if logo_enabled
        else
          avatar_initials(item) if avatar_enabled
        end
      end)
      if item.verified? && !item.is_a?(Comment) and avatar_enabled
        concat(content_tag(:div, class: 'hc-tooltip') do
          concat verified_icon(
            item_class:  ''
          )
          concat hc_tooltip(description, position: 'right', min_width: '120px', text_align: 'center')
        end)
      end
      concat(content_tag(:div, class: "hc-author__text") do
        concat content_tag(:div, item.respond_to?(:search_highlights) ? item.get_highlights(:display_name, display_name) : display_name, class: 'bold')
        if item.is_a?(Comment)
          concat store_description(
            label:       label,
            description: description,
            item_class:  item.class.name.downcase
          )
        end
      end)
      # Verified text for mobile screens and when the avatar is hidden through global settings.
      if item.verified? && !item.is_a?(Comment)
        concat verified_icon(
          item_class:  "hc-verified-text-icon #{'hide--above__sm' if avatar_enabled}"
        )
        concat content_tag(:span, description, class: "hc-verified-text #{'hide--above__sm' if avatar_enabled}")
      end
    end
  end

  def avatar_logo(item)
    return nil if item.display_logo.blank?
    image_tag(item.display_logo, class: 'hc-avatar hc-avatar__logo')
  end

  def avatar_initials(item)
    content_tag(:div, item.display_initials, class: 'hc-avatar hc-avatar__initials', style: 'background-color:'+ colorize(item.display_name))
  end

  def header_with_action(heading, action, h: :h1)
    content_tag(:header, class: 'header-with-action') do
      concat content_tag(h, heading, class: 'header-with-action__heading')
      concat content_tag(:span, action, class: 'header-with-action__action-wrapper')
    end
  end

  def heading_with_line(heading, h = :h1)
    content_tag(h, class: 'hc-heading-with-line') do
      content_tag(:span, heading)
    end
  end

  def email_icon(customer)
    if customer.suppressed?
      render 'back/shared/unsubscription_info', customer: customer
    else
      hc_icon 'envelope'
    end
  end

  def kb_article_url(article)
    "#{ ENV['KNOWLEDGE_BASE_URL'] }/#{ t(article, scope: 'kb_articles') }"
  end

  def kb_article(article, label: 'Learn more', color: false, icon: true, nowrap: false)
    content_tag(
      :a, href: "#{ ENV['KNOWLEDGE_BASE_URL'] }/#{ t 'kb_articles.' + article, default: 'kb' }",
      class: "hc-kb-article #{color if color} #{'hc-kb-article--nowrap' if nowrap}",
      target: '_blank') do
      if icon
        concat hc_icon 'question-circle'
        concat ' '
      end
      concat content_tag :span, label
    end
  end

  def info_with_label(info, label, html_class: false)
    content_tag(:div, class: "info-with-label#{ ' ' + html_class if html_class }") do
      concat content_tag(:span, label + ':', class: 'info-with-label__label bold')
      concat ' '
      concat content_tag(:span, info, class: 'info-with-label__info')
    end
  end

  def color(color)
    Rails.configuration.colors[color]
  end

  def abuse_report_status(status, count, dropdown=false)
    content_tag :span do
      case status.to_s
      when 'open'
        concat hc_icon 'exclamation-circle justified'
      when 'resolved'
        concat hc_icon 'check justified'
      end
      concat ' '
      concat status.to_s.humanize
      concat ' '
      concat "(#{count})"
      if dropdown
        concat ' '
        concat hc_icon 'sort-desc justified'
      end
    end
  end

  def new_button(text, url, size: 'normal', icon: true)
    case size
    when 'normal'
      html_class = 'hc-primary-button'
    when 'small'
      html_class = 'hc-primary-button--small'
    end

    link_to url, class: html_class do
      if icon
        concat hc_icon 'plus'
        concat ' '
      end
      concat text
    end
  end

  def edit_button(url, size: 'normal', icon: true)
    case size
    when 'normal'
      html_class = 'hc-secondary-button'
    when 'small'
      html_class = 'hc-secondary-button--small'
    end

    link_to url, class: html_class do
      if icon
        concat hc_icon 'pencil'
        concat ' '
      end
      concat 'Edit'
    end
  end

  def delete_button(url, size: 'normal', icon: true, confirm: 'Are you sure you want to delete this item?', method: :delete)
    case size
    when 'normal'
      html_class = 'hc-danger-button'
    when 'small'
      html_class = 'hc-danger-button--small'
    end

    link_to url, class: html_class, method: method, data: { confirm: confirm } do
      if icon
        concat hc_icon 'trash'
        concat ' '
      end
      concat 'Delete'
    end
  end

  def back_button(text = 'Back', size: 'normal')
    case size
    when 'normal'
      html_class = 'hc-secondary-button'
    when 'small'
      html_class = 'hc-secondary-button--small'
    end

    link_to text, :back, class: html_class
  end

  def info_icon(text)
    hc_icon 'info-circle', title: text
  end

  def hc_breadcrumbs
    content_tag(:nav, class: 'hc-breadcrumbs') do
      render_breadcrumbs separator: hc_icon('angle-right')
    end
  end

  def hc_simple_format(str)
    while str.include? "\n\n\n" do
      str = str.sub("\n\n\n", "<br />\n\n")
    end
    str = simple_format(str)
    str
  end

  def link_to_blank(body, url_options = {}, html_options = {})
    # TODO do block does not work with this :(
    link_to(body, url_options, html_options.merge(target: "_blank"))
  end

  def checkbox_toggle(field, hint = false, txt = false, txt_off = 'Disabled', txt_on = 'Enabled')
    # TODO it is not possible to pass txt unless you also pass hint.. problem with argument ordering
    if txt == false
      txt = field.to_s.humanize
    end
    content_tag(:div, class: 'hc-checkbox-toggle') do
      concat check_box_tag(field, true, '',class: 'hc-checkbox-toggle__input')
      concat render partial: 'helpful_components/checkbox_toggle/label', locals: { label_for: 'test', txt: txt, txt_off: txt_off, txt_on: txt_on }
      concat form_hint hint if hint
    end
  end

  def hc_code(code, language)
    formatter = Rouge::Formatters::HTML.new(css_class: 'hc-code')
    lexer = Rouge::Lexer.find(language)
    content_tag(:pre, class: 'hc-code__wrapper') do
      content_tag(:div, class: 'hc-code') do
        formatter.format(lexer.lex(code)).html_safe
      end
    end
  end

  def hc_badge(text = nil, kind: 'primary', &block)
    if block.present?
      content = capture(&block)
      content_tag :div, content, class: "hc-badge hc-badge--#{kind}"
    else
      content = text
      content_tag :div, content, class: "hc-badge hc-badge--#{kind}"
    end
  end

  def coupon_code_status_icon(status)
    hc_icon(STATUS_ICONS[:coupon_code][status.to_sym])
  end

  def discount_coupon_in_use_icon(status)
    hc_icon(STATUS_ICONS[:discount_coupon][status.to_sym])
  end

  def promotion_status_icon(status)
    hc_icon(STATUS_ICONS[:promotion][status.to_sym])
  end

  def promotion_incentive_icon(status)
    hc_icon(STATUS_ICONS[:promotion][status.to_sym])
  end

  def review_request_status_icon(status)
    hc_icon(STATUS_ICONS[:review_request][status.to_sym])
  end

  def rqa_status_icon(status)
    hc_icon(STATUS_ICONS[:rqa][status.to_sym])
  end

  def hc_icon(icon, args = {})
    options = icon.split
    shape   = Rails.configuration.icons[options.first.to_sym]

    icon_builder(shape, options, args)
  end

  def icon_builder(shape, options, args = {})
    # TODO these all could be implemented in a cleaner way.. example: https://github.com/bokmann/font-awesome-rails/blob/master/app/helpers/font_awesome/rails/icon_helper.rb
    svg_title   = args[:title]       || false
    nested_icon = args[:nested_icon] || false
    resize      = args[:resize]      || 1
    style       = args[:style]       || nil   # nil and NOT false so that style attribute is not passed at all when there are no inline styles

    html_class  = "hc-icon #{ args[:class] if args[:class].present? } #{ 'hc-icon--justified' if nested_icon }"

    options.each do |option|
      html_class << " hc-icon--#{option}"
    end

    scale = 1792 / resize

    content_tag( :svg,
                 class:   html_class,
                 height:  "1em", # This acts as a fallback. Desired height is set from CSS
                 style:   style,
                 viewBox: "0 0 #{scale} #{scale}",
                 width:   "1em", # This acts as a fallback. Desired width is set from CSS
                 xmlns:   "http://www.w3.org/2000/svg" ) do

      concat( content_tag(:g) do
                concat( "<title>#{svg_title}</title>".html_safe ) if svg_title
                concat( tag(:path, d: shape) )
                # Add empty & transparent square to show html title attribute
                # tooltip when hovering on empty parts of the icon
                concat( '<rect class="hc-icon__transparent-background"></rect>'.html_safe )
              end )

      if nested_icon
        nested_icon_options = nested_icon[:options].split
        nested_icon_shape   = Rails.configuration.icons[nested_icon_options.first.to_sym]
        nested_icon_class   = "hc-icon hc-icon--nested"

        case nested_icon[:position]
        when 'north-east'
          transform = 'translate(500,-200)'
        when 'north-west'
          transform = 'translate(-300,-200)'
        when 'south-east'
          transform = 'translate(500,200)'
        when 'south-west'
          transform = 'translate(-300,200)'
        else
          transform = nil
        end

        nested_icon_options.shift

        nested_icon_options.each do |option|
          nested_icon_class << " hc-icon--#{option}"
        end

        concat( content_tag(:g, class: nested_icon_class, transform: transform) do
                  concat( tag(:path, d: nested_icon_shape) )
                end )
      end
    end
  end

  # Generate randon color in HSL format based on the string passed. Optional parameters are saturation and lightness
  # Inspired from https://medium.com/@pppped/compute-an-arbitrary-color-for-user-avatar-starting-from-his-username-with-javascript-cd0675943b66
  def colorize(string, saturation = 40, lightness = 68)
    h = string.chars.reduce(0) { |hash, c| aggr = c.ord + ((hash << 5) - hash) } % 360
    'hsl('+h.to_s+', '+saturation.to_s+'%, '+lightness.to_s+'%)'
  end

  def link_to_tos(content: 'Terms of service')
    link_to_blank content, 'https://www.helpfulcrowd.com/tos/'
  end

  def link_to_pp(content: 'Privacy policy')
    link_to_blank content, 'https://www.helpfulcrowd.com/privacy-policy/'
  end

  def current_theme
    return current_user.store.settings(:design).value["theme"]
  end
end
