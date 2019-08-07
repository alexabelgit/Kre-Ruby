class Api::EmailEventsController < ApplicationController

  skip_before_action :verify_authenticity_token
  http_basic_authenticate_with name: ENV['SENDGRID_EVENTS_USER'], password: ENV['SENDGRID_EVENTS_PASSWORD']

  def create

    if params[:_json]
      events  = params[:_json]
      columns = EmailEvent.columns_hash

      events.each do |event|
        props = { 'raw'                  => event.to_json,
                  'event_post_timestamp' => Time.now.to_i }
        unique_args   = Hash.new
        smtp_id       = ''
        sg_message_id = ''
        event.each do |key, value|
          next if key == 'id' || key == 'email'

          if key == 'type'
            props['type_id'] = value
          elsif columns[key] then
            if key == 'smtp-id'
              smtp_id = value.gsub('<', '').gsub('>', '')
            elsif key == 'sg_message_id'
              sg_message_id = value
            end

            if value.is_a? String
              value = value.gsub(/\\\//, '/')
            elsif value.is_a? Array or value.is_a? Hash then
              value = value.to_json
            end
            props[key] = value
          else
            unique_args[key] = to_string(value)
          end
        end

        email = nil

        if unique_args['helpful_id'].present?
          email = Email.find_by_helpful_id(unique_args['helpful_id'])
        elsif smtp_id.present?
          email = Email.where('smtp-id' => smtp_id).first
        elsif sg_message_id.present?
          email = Email.find_by_sg_message_id(sg_message_id)
        end

        if email.present? #TODO do some stuff if we really want to track all mails on our side. At this moment we only track emails associated with review requets
          email.update_attributes(sg_message_id: sg_message_id) if email.sg_message_id.blank?
          props['additional_arguments'] = unique_args.to_json
          email_event                   = EmailEvent.new(props)
          email_event.email             = email
          email_event.save
        end
      end

      render json: { message: 'Post accepted' }
    else
      render json:   { message: :error,
                       error:   'Unexpected content-type. Expecting JSON.' },
             status: 400
    end
  end

  def show
    if EmailEvent.where(id: params[:id]).present?
      event = EmailEvent.find(params[:id])
      render json: event
    else
      render json:   { message: :error,
                       error:   "Event record with ID #{params[:id]} not found." },
             status: 404
    end
  end

  def update
    id = params[:id]
    if EmailEvent.where(id: id).present?
      event = EmailEvent.find(id)
      event.update(email_event_params(params))
      render json: event
    else
      render json:   { message: :error,
                       error:   "Event record with ID #{params[:id]} not found." },
             status: 404
    end
  end

  def destroy
    id = params[:id]
    if EmailEvent.where(id: id).present?
      event = EmailEvent.find(id)
      event.destroy
      render json: {}
    else
      render json:  { message: :error,
                      error:   "Event record with ID #{params[:id]} not found." },
             status: 404
    end
  end

  private
  def email_event_params(params)
    params.require(:email_event).permit(:timestamp, :event, :email, :'smtp-id', :sg_event_id, :sg_message_id, :category, :newsletter,
                                        :response, :reason, :ip, :useragent, :attempt, :status, :type, :url, :additional_arguments,
                                        :event_post_timestamp, :raw, :asm_group_id)
  end

  def to_string(value)
    (value.is_a? Array or value.is_a? Hash) ? value.to_json : value
  end

end
