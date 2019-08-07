class Front::FlagsController < FrontController

  skip_before_action :verify_authenticity_token, only: [ :create ]

  def create
    @flag = Flag.new(flaggable: @flaggable)

    if session.validate_record?(@flaggable, scope: :flag)
      session.store_record(@flaggable, scope: :flag) if @flag.save
    else
      @flag = @flaggable.flags.first
    end

    respond_to do |format|
      format.html
      format.js
    end
  end

end
