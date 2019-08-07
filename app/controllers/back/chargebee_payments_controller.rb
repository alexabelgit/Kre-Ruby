module Back
  class ChargebeePaymentsController < BackController
    skip_before_action :check_live, :set_announcements

    def confirm
      hosted_page = Payments::ChargebeeHostedPage.retrieve params[:hosted_page_id]

      if hosted_page.blank?
        flash[:error] = 'Something went wrong during payment retrieval'
        return
      end

      outcome = hosted_page.handle_submission
      case outcome.status
      when :confirmed
        subscription = outcome.result
        success_message = "You have successfully subscribed to a plan"
        flash[:success] = success_message, :fade
        render json: { status: :success, subscription_id: subscription.id }, status: :ok
      when :rolled_back
        error_message = "You quit subscription process without completing it.
                         If you wish to subscribe to a plan, please start over and
                         make sure to complete all the steps."
        flash[:error] = error_message
        render json: { status: :cancelled }, status: :ok
      when :error
        error_message = "Payment succeeded but we could not process it.
                         Please contact us at #{ helpers.mail_to billing_email }
                         to resolve this issue."
        flash[:error] = error_message
      else
        head :ok
      end
    end

    def portal
      subscription = Subscription.find_by id: params[:subscription_id]
      if subscription
        inputs = {
          redirect_url: billing_back_settings_url,
          customer:     { id: subscription.id_from_provider }
        }
        result = ChargeBee::PortalSession.create(inputs)
        render json: { portal_session: result.portal_session }
      else
        render json: { error: :no_subscription_found }, status: 404
      end
    end

    private

    def billing_email
      ENV['BILLING_EMAIL']
    end
  end
end
