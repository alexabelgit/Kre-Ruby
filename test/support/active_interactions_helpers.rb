module ActiveInteractonsHelpers
  class BaseOutcome
    def result
      self
    end

    def errors
      []
    end

    def valid?
      raise 'Calling method of abstract class'
    end

    def invalid?
      !valid?
    end
  end

  class ValidOutcome < BaseOutcome
    def valid?
      true
    end
  end

  class InvalidOutcome < BaseOutcome
    def valid?
      false
    end
  end

  def self.included(klass)
    klass.extend ClassMethods
  end

  module ClassMethods
  end
end
