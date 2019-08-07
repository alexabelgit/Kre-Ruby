class Result
  attr_reader :entity, :status

  def initialize(success:, entity: nil, error: nil, status: nil)
    @entity = entity
    @success = success
    @errors = Array.wrap(error) # wrapping allows to pass single error without putting it into []
    @status = status
  end

  def success?
    @success
  end

  def failure?
    !success?
  end

  def first_error
    @errors.first
  end

  def error=(new_value)
    @errors << new_value
  end

  def error_message
    @errors.join '. '
  end

  def to_s
    { success?: success?, entity: @entity, errors: @errors.to_s , status: @status}.to_s
  end
end
