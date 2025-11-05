class OrderMailer < ApplicationMailer
  default from: 'to.miahangela@gmail.com'

  # Send email when order is placed
  def order_placed(order, email_override: nil)
    @order = order
    @customer = order.customer
    @merchant = order.merchant
    @order_items = order.order_items.includes(:product)
    @delivery_address = order.delivery_address

    # Use override email if provided, otherwise use customer's stored email
    recipient_email = email_override || @customer.email

    # Use GCash-specific template for GCASH orders
    if order.gcash?
      mail(
        to: recipient_email,
        subject: "GCash Payment Required - #{@order.reference_number}",
        template_name: 'order_placed_gcash'
      )
    else
      mail(
        to: recipient_email,
        subject: "Order Placed Successfully - #{@order.reference_number}",
        template_name: 'order_placed'
      )
    end
  end

  # Send email when order is confirmed
  def order_confirmed(order)
    @order = order
    @customer = order.customer
    @merchant = order.merchant

    mail(
      to: @customer.email,
      subject: "Order Confirmed - #{@order.reference_number}"
    )
  end

  # Send email when order is out for delivery
  def order_out_for_delivery(order)
    @order = order
    @customer = order.customer
    @merchant = order.merchant

    mail(
      to: @customer.email,
      subject: "Your Order is Out for Delivery - #{@order.reference_number}"
    )
  end

  # Send email when order is completed
  def order_completed(order)
    @order = order
    @customer = order.customer
    @merchant = order.merchant

    mail(
      to: @customer.email,
      subject: "Order Completed - #{@order.reference_number}"
    )
  end

  # Send email when order is cancelled
  def order_cancelled(order)
    @order = order
    @customer = order.customer
    @merchant = order.merchant

    mail(
      to: @customer.email,
      subject: "Order Cancelled - #{@order.reference_number}"
    )
  end

  # Send email to merchant when payment proof is received
  def payment_proof_received(order)
    @order = order
    @merchant = order.merchant
    @customer = order.customer

    mail(
      to: @merchant.email,
      subject: "Payment Proof Received - #{@order.reference_number}"
    )
  end

  # Send email when payment is verified
  def payment_verified(order)
    @order = order
    @customer = order.customer
    @merchant = order.merchant

    mail(
      to: @customer.email,
      subject: "Payment Verified - #{@order.reference_number}"
    )
  end

  # Send email when payment fails
  def payment_failed(order)
    @order = order
    @customer = order.customer
    @merchant = order.merchant

    mail(
      to: @customer.email,
      subject: "Payment Failed - #{@order.reference_number}"
    )
  end
end
