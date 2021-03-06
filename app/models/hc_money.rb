require 'money'

Money.locale_backend = :i18n

class HcMoney
  class <<self
    attr_accessor :default_formatting_rules
  end

  self.default_formatting_rules = {
    # Ruby money currently has this as false, which is wrong for the vast
    # majority of locales.
    sign_before_symbol: true,
    translate: true
  }

  attr_reader :money
  delegate    :cents, :currency, to: :money

  def initialize(amount, options = {})
    @money    = Monetize.parse([amount, (options[:currency] || 'USD')].join)
    @options  = HcMoney.default_formatting_rules.merge(options)
  end

  def amount_in_cents
    (cents / currency.subunit_to_unit.to_f * 100).round
  end

  # @return [Float] the value of this money object as a float
  def to_f
    @money.to_f
  end

  # @return [String] the value of this money object formatted according to its options
  def to_s
    money.format(options)
  end

  # More of the same, but USD as this is commonly used
  def as_usd
    convert_to('USD')
  end

  # Converts the amount based on the provided currency ISO
  def convert_to(currency_iso)
    HcMoney.new(
      @money.exchange_to(Money::Currency.find(currency_iso).iso_code).to_f,
      currency: currency_iso
    )
  end

  # 1) prevent blank, breaking spaces
  # 2) prevent escaping of HTML character entities
  def to_html(opts = { html: true })
    # html option is deprecated and we need to fallback to html_wrap
    opts[:html_wrap] = opts[:html]
    opts.delete(:html)

    output = money.format(options.merge(opts))
    if opts[:html_wrap]
      output.gsub!(/<\/?[^>]*>/, '') # we don't want wrap every element in span
      output = output.sub(' ', '&nbsp;').html_safe
    end

    output
  end

  def as_json(*)
    to_s
  end

  def decimal_mark
    options[:decimal_mark] || money.decimal_mark
  end

  def thousands_separator
    options[:thousands_separator] || money.thousands_separator
  end

  def <=>(obj)
    money == obj.money
  end

  private

  attr_reader :options
end
