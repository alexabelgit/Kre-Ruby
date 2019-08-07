require "#{File.dirname(__FILE__)}/models/base.rb"
Dir.glob("#{File.dirname(__FILE__)}/models/*").each { |file| require(file) }
