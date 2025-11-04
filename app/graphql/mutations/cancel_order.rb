# frozen_string_literal: true

module Mutations
  class CancelOrder < BaseMutation
    description "Cancel an order - Customers can cancel their own pending orders"

    argument :id, ID, required: true

    field :order, Types::OrderType, null: true
    field :errors, [String], null: false

    def resolve(id:)
      current_user = context[:current_merchant]
      return { order: nil, errors: ["Authentication required"] } unless current_user

      order = Order.find_by(id: id)
      return { order: nil, errors: ["Order not found"] } unless order

      # Customers can only cancel their own orders
      if current_user.customer?
        # Find the order through customer email
        unless order.customer.email == current_user.email
          return { order: nil, errors: ["You can only cancel your own orders"] }
        end
      # Merchants can cancel orders for their products
      elsif current_user.merchant?
        unless order.merchant_id == current_user.id
          return { order: nil, errors: ["You can only cancel orders for your products"] }
        end
      # Admins can cancel any order
      elsif !current_user.admin?
        return { order: nil, errors: ["Not authorized"] }
      end

      # Can only cancel pending orders
      unless order.status == 'PENDING'
        return { order: nil, errors: ["Can only cancel pending orders. This order is #{order.status.downcase}"] }
      end

      # Update order status to cancelled
      if order.update(status: 'CANCELLED')
        # Restore product stock
        order.order_items.each do |item|
          product = item.product
          product.increment!(:stock_quantity, item.quantity)
        end

        # Send cancellation email
        begin
          OrderMailer.order_cancelled(order).deliver_later
          Rails.logger.info "Order cancellation email queued for order #{order.reference_number}"
        rescue => e
          Rails.logger.error "Failed to send order cancellation email: #{e.message}"
          # Don't fail the cancellation if email fails
        end

        { order: order, errors: [] }
      else
        { order: nil, errors: order.errors.full_messages }
      end
    end
  end
end
