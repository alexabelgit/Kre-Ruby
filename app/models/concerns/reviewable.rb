module Reviewable
  extend ActiveSupport::Concern

  def store
    case self.class.name
    when Store.name
      self
    when Product.name
      super
    end
  end

  def name
    super
  end

  def url
    super
  end

  def public_image
    case self.class.name
    when Store.name
      logo
    when Product.name
      featured_image
    end
  end

end
