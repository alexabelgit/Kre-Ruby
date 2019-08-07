require 'active_interaction'

class ApplicationCommand < ActiveInteraction::Base
  def given_inputs
    inputs.select { |key| given?(key) }
  end
end
