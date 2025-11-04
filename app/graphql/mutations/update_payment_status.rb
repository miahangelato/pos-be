module Mutations
  class UpdatePaymentStatus < BaseMutation
    description "Update order payment status"

    # Arguments (BaseMutation will auto-generate input type)
    argument :id, ID, required: true
    argument :payment_status, String, required: true

    # Return fields
    field :order, Types::OrderType, null: true
    field :errors, [String], null: false

    def resolve(id:, payment_status:)
      
      # Ensure user is authenticated
      current_user = context[:current_user]
      return { order: nil, errors: ["Authentication required"] } unless current_user

      # Check permission - only merchants and admins can update payment status
      unless current_user.can_manage_orders?
        return { order: nil, errors: ["You do not have permission to update payment status"] }
      end

      # Validate payment status
      valid_statuses = %w[PAYMENT_PENDING PAID FAILED]
      unless valid_statuses.include?(payment_status)
        return { order: nil, errors: ["Invalid payment status. Must be one of: #{valid_statuses.join(', ')}"] }
      end

      begin
        # Handle both Global ID and plain integer ID formats
        if id.to_s.start_with?('Z2lk') || id.to_s.include?('gid://')
          # This is a Global ID (either base64 encoded or raw format)
          decoded_id = id.to_s.start_with?('Z2lk') ? Base64.decode64(id) : id
          parsed_order = GlobalID.find(decoded_id)
          raise ActiveRecord::RecordNotFound, "Order not found" unless parsed_order.is_a?(Order)
          order = parsed_order
        else
          # This is a plain integer ID - find directly
          if current_user.admin?
            order = Order.find_by!(id: id)
          else
            order = Order.find_by!(id: id, merchant: current_user)
          end
        end
        
        # For Global ID case with merchant permission check
        if id.to_s.start_with?('Z2lk') || id.to_s.include?('gid://')
          unless current_user.admin? || order.merchant == current_user
            raise ActiveRecord::RecordNotFound, "Order not found or does not belong to your account"
          end
        end

        # For GCASH orders, check if payment proof is submitted
        if order.gcash? && payment_status == 'PAID'
          unless order.payment_proof&.present?
            return { order: nil, errors: ["Payment proof must be submitted before marking as paid"] }
          end
          
          # Mark payment proof as verified
          order.payment_proof.update(status: 'VERIFIED', verified_at: Time.current)
        end

        old_payment_status = order.payment_status

        if order.update(payment_status: payment_status)
          # Send email notification based on new payment status
          begin
            if payment_status == 'PAID'
              OrderMailer.payment_verified(order).deliver_later
              Rails.logger.info "Payment verified email queued for order #{order.reference_number}"
            elsif payment_status == 'FAILED'
              OrderMailer.payment_failed(order).deliver_later
              Rails.logger.info "Payment failed email queued for order #{order.reference_number}"
            end
          rescue => e
            Rails.logger.error "Failed to send payment status email: #{e.message}"
            # Don't fail the update if email fails
          end

          { order: order, errors: [] }
        else
          { order: nil, errors: order.errors.full_messages }
        end
      rescue ActiveRecord::RecordNotFound
        { order: nil, errors: ["Order not found"] }
      rescue => e
        { order: nil, errors: [e.message] }
      end
    end
  end
end
