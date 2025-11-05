module Mutations
  class UpdateOrderStatus < BaseMutation
    description "Update order status"

    # Arguments
    argument :id, ID, required: true
    argument :status, String, required: true

    # Return fields
    field :order, Types::OrderType, null: true
    field :errors, [String], null: false

    def resolve(id:, status:)
      # Ensure user is authenticated
      current_user = context[:current_user]
      return { order: nil, errors: ["Authentication required"] } unless current_user

      # Check permission
      unless current_user.can_manage_orders?
        return { order: nil, errors: ["You do not have permission to update order status"] }
      end

      # Validate status
      valid_statuses = %w[PENDING CONFIRMED OUT_FOR_DELIVERY COMPLETED CANCELLED]
      unless valid_statuses.include?(status)
        return { order: nil, errors: ["Invalid status. Must be one of: #{valid_statuses.join(', ')}"] }
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
        
        old_status = order.status
        
        if order.update(status: status)
          # Send email notification based on new status
          begin
            case status
            when 'CONFIRMED'
              OrderMailer.order_confirmed(order).deliver_now
              Rails.logger.info "✅ Order confirmed email sent for order #{order.reference_number} to #{order.customer.email}"
            when 'OUT_FOR_DELIVERY'
              OrderMailer.order_out_for_delivery(order).deliver_now
              Rails.logger.info "✅ Order out for delivery email sent for order #{order.reference_number} to #{order.customer.email}"
            when 'COMPLETED'
              OrderMailer.order_completed(order).deliver_now
              Rails.logger.info "✅ Order completed email sent for order #{order.reference_number} to #{order.customer.email}"
            when 'CANCELLED'
              OrderMailer.order_cancelled(order).deliver_now
              Rails.logger.info "✅ Order cancelled email sent for order #{order.reference_number} to #{order.customer.email}"
            end
          rescue Net::OpenTimeout, Net::ReadTimeout, Errno::ETIMEDOUT => e
            Rails.logger.warn "⚠️  SMTP timeout for order status email, queuing for background: #{e.message}"
            # Fallback to background delivery for timeouts
            case status
            when 'CONFIRMED'
              OrderMailer.order_confirmed(order).deliver_later
            when 'OUT_FOR_DELIVERY'
              OrderMailer.order_out_for_delivery(order).deliver_later
            when 'COMPLETED'
              OrderMailer.order_completed(order).deliver_later
            when 'CANCELLED'
              OrderMailer.order_cancelled(order).deliver_later
            end
          rescue => e
            Rails.logger.error "❌ Failed to send order status email: #{e.class}: #{e.message}"
            Rails.logger.error e.backtrace.join("\n")
            # Don't fail the status update if email fails
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