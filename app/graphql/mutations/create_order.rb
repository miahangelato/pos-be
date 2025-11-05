module Mutations
  class CreateOrder < BaseMutation
    description "Create a new order"

    # Arguments
    argument :customer_id, ID, required: false
    argument :customer_attributes, Types::CustomerInputType, required: false
    argument :order_items, [Types::OrderItemInputType], required: true
    argument :order_type, String, required: true
    argument :payment_method, String, required: true
    argument :shipping_method, String, required: false
    argument :delivery_address_attributes, Types::DeliveryAddressInputType, required: false
    argument :voucher_code, String, required: false

    # Return fields
    field :order, Types::OrderType, null: true
    field :errors, [String], null: false

    def resolve(customer_id: nil, customer_attributes: nil, order_items:, order_type:, payment_method:, shipping_method: nil, delivery_address_attributes: nil, voucher_code: nil)
      # Ensure user is authenticated
      current_user = context[:current_user]
      return { order: nil, errors: ["Authentication required"] } unless current_user

      # Check permission
      unless current_user.can_create_orders?
        return { order: nil, errors: ["You do not have permission to create orders"] }
      end

      # For merchants/admins, either customer_id or customer_attributes must be provided
      # For customers, they are creating orders for themselves
      if current_user.merchant? && !customer_id && !customer_attributes
        return { order: nil, errors: ["Either customer_id or customer_attributes must be provided"] }
      end

      begin
        # Convert GraphQL input objects to hashes if they exist
        customer_attrs_hash = customer_attributes&.to_h
        delivery_address_attrs_hash = delivery_address_attributes&.to_h
        order_items_hash = order_items.map(&:to_h)
        
        result = nil
        
        ActiveRecord::Base.transaction do
          
          # Determine merchant and customer based on who's creating the order
          if current_user.customer?
            # Customer is creating their own order
            # We need to determine which merchant owns the products
            # For now, we'll get the merchant from the first product
            first_product = Product.find(order_items_hash.first[:product_id])
            merchant = first_product.merchant
            
            # Create or find customer record for this customer under this merchant
            customer = merchant.customers.find_or_create_by!(email: current_user.email) do |c|
              c.first_name = current_user.name.split(' ').first || current_user.name
              c.last_name = current_user.name.split(' ')[1..-1]&.join(' ') || ''
              c.mobile_number = current_user.email # Default to email if no mobile
            end
          elsif current_user.admin?
            # Admin is creating an order - determine merchant from products
            first_product = Product.find(order_items_hash.first[:product_id])
            merchant = first_product.merchant
            
            # Find customer - either by ID or by finding/creating from attributes
            if customer_id
              # Use existing customer by ID (can be from any merchant)
              customer = Customer.find(customer_id)
              # Note: customer_attrs_hash will be used for email override only, not updating the record
            else
              # Find or create customer from attributes under the determined merchant
              customer = find_or_create_customer(merchant, customer_attrs_hash)
            end
          else
            # Merchant is creating an order for a customer
            merchant = current_user
            
            # Find customer - either by ID or by finding/creating from attributes
            if customer_id
              # Use existing customer by ID (must belong to this merchant)
              customer = current_user.customers.find(customer_id)
              # Note: customer_attrs_hash will be used for email override only, not updating the record
            else
              # Find or create customer from attributes
              customer = find_or_create_customer(current_user, customer_attrs_hash)
            end
          end
          
          # Determine payment status based on payment method
          # CASH orders are immediately PAID, GCASH orders are PAYMENT_PENDING
          payment_status = payment_method == 'CASH' ? 'PAID' : 'PAYMENT_PENDING'
          
          # Create order
          order = Order.new(
            merchant: merchant,
            customer: customer,
            order_type: order_type,
            payment_method: payment_method,
            shipping_method: shipping_method,
            status: 'PENDING',
            payment_status: payment_status
          )

          # Create delivery address if provided
          if delivery_address_attrs_hash && order_type == 'ONLINE'
            # Map frontend field names to database column names
            mapped_delivery_attrs = {
              province: delivery_address_attrs_hash[:province],
              city: delivery_address_attrs_hash[:city],
              barangay: delivery_address_attrs_hash[:barangay],
              street: delivery_address_attrs_hash[:street],
              room_unit: delivery_address_attrs_hash[:unit_floor],  # Map unit_floor to room_unit
              building: delivery_address_attrs_hash[:building_name], # Map building_name to building
              landmark: delivery_address_attrs_hash[:landmark],
              remarks: delivery_address_attrs_hash[:remarks]
            }.compact
            
            delivery_address = order.build_delivery_address(mapped_delivery_attrs)
            return { order: nil, errors: delivery_address.errors.full_messages } unless delivery_address.valid?
          end

          # Add order items
          subtotal = 0
          order_items_hash.each do |item_attrs|
            # Find product based on user role
            if current_user.customer?
              # Customer: can order from any merchant
              product = Product.find(item_attrs[:product_id])
              # Verify all products belong to the same merchant
              if product.merchant_id != merchant.id
                raise StandardError.new("All products must belong to the same merchant")
              end
            elsif current_user.admin?
              # Admin: can use any product from any merchant
              product = Product.find(item_attrs[:product_id])
              # Verify all products belong to the determined merchant
              if product.merchant_id != merchant.id
                raise StandardError.new("All products must belong to the same merchant")
              end
            else
              # Merchant: can only use their own products
              product = current_user.products.find(item_attrs[:product_id])
            end
            
            # Check stock for physical products
            if product.physical? && product.stock_quantity && product.stock_quantity < item_attrs[:quantity]
              raise StandardError.new("Insufficient stock for #{product.name}")
            end

            order_item = order.order_items.build(
              product: product,
              quantity: item_attrs[:quantity],
              price_at_purchase: product.price
            )
            
            subtotal += (product.price * item_attrs[:quantity])
          end

          # Calculate totals
          order.subtotal = subtotal
          order.shipping_fee = calculate_delivery_fee(order)
          order.convenience_fee = calculate_convenience_fee(order)
          order.grand_total = order.subtotal + order.shipping_fee + order.convenience_fee

          # Apply voucher discount if provided
          if voucher_code.present?
            # TODO: Implement voucher logic
            order.voucher_discount = 0
          end

          order.grand_total -= (order.voucher_discount || 0)

          Rails.logger.info "Order before save: #{order.inspect}"
          Rails.logger.info "Order items count: #{order.order_items.length}"
          order.order_items.each_with_index do |item, idx|
            Rails.logger.info "  Item #{idx}: #{item.inspect}"
            Rails.logger.info "  Item valid? #{item.valid?}"
            Rails.logger.info "  Item errors: #{item.errors.full_messages}" unless item.valid?
          end
          Rails.logger.info "Order valid? #{order.valid?}"
          Rails.logger.info "Order errors: #{order.errors.full_messages}" unless order.valid?

          if order.save
            # Update stock for physical products
            order.order_items.each do |item|
              if item.product.physical? && item.product.stock_quantity
                item.product.update!(stock_quantity: item.product.stock_quantity - item.quantity)
              end
            end

            # Reload order to ensure we return fresh data (including updated customer)
            order.reload
            
            result = { order: order, errors: [] }
          else
            result = { order: nil, errors: order.errors.full_messages }
          end
        end
        
        # Send email only if order was created successfully and transaction is committed
        if result[:order] && result[:errors].empty?
          send_order_confirmation_email(result[:order], customer_attrs_hash)
        end
        
        result
      rescue ActiveRecord::RecordNotFound => e
        Rails.logger.error "RecordNotFound in CreateOrder: #{e.message}"
        Rails.logger.error e.backtrace.join("\n")
        { order: nil, errors: ["Product not found"] }
      rescue ActiveRecord::RecordInvalid => e
        Rails.logger.error "RecordInvalid in CreateOrder: #{e.message}"
        Rails.logger.error e.backtrace.join("\n")
        { order: nil, errors: [e.message] }
      rescue => e
        Rails.logger.error "Error in CreateOrder: #{e.message}"
        Rails.logger.error e.backtrace.join("\n")
        { order: nil, errors: [e.message] }
      end
    end

    private

    def update_customer_if_changed(customer, customer_attrs)
      # Update customer details if they've changed
      # This allows updating customer info when selecting from search
      update_attrs = {}
      
      if customer_attrs[:first_name].present? && customer_attrs[:first_name] != customer.first_name
        update_attrs[:first_name] = customer_attrs[:first_name]
      end
      
      if customer_attrs[:last_name].present? && customer_attrs[:last_name] != customer.last_name
        update_attrs[:last_name] = customer_attrs[:last_name]
      end
      
      if customer_attrs[:email].present? && customer_attrs[:email] != customer.email
        # Check if email is already taken by another customer
        existing = customer.merchant.customers.find_by(email: customer_attrs[:email])
        if existing && existing.id != customer.id
          raise StandardError, "Email #{customer_attrs[:email]} is already taken by another customer"
        end
        update_attrs[:email] = customer_attrs[:email]
      end
      
      if customer_attrs[:mobile_number].present? && customer_attrs[:mobile_number] != customer.mobile_number
        # Check if mobile number is already taken by another customer
        existing = customer.merchant.customers.find_by(mobile_number: customer_attrs[:mobile_number])
        if existing && existing.id != customer.id
          raise StandardError, "Mobile number #{customer_attrs[:mobile_number]} is already taken by another customer"
        end
        update_attrs[:mobile_number] = customer_attrs[:mobile_number]
      end
      
      if update_attrs.present?
        Rails.logger.info "Updating customer #{customer.id} with: #{update_attrs.inspect}"
        customer.update!(update_attrs)
        customer.reload # Reload to get fresh data from database
      end
      
      customer
    end

    def find_or_create_customer(merchant, customer_attrs)
      # Validate customer_attrs is present and has required fields
      raise ArgumentError, "Customer attributes must be provided" if customer_attrs.nil?
      raise ArgumentError, "Customer email is required" if customer_attrs[:email].blank?
      
      # Try to find customer by email first
      customer = merchant.customers.find_by(email: customer_attrs[:email])
      
      if customer
        # Customer exists with this email - update info if changed
        update_attrs = {}
        
        if customer_attrs[:first_name].present? && customer_attrs[:first_name] != customer.first_name
          update_attrs[:first_name] = customer_attrs[:first_name]
        end
        
        if customer_attrs[:last_name].present? && customer_attrs[:last_name] != customer.last_name
          update_attrs[:last_name] = customer_attrs[:last_name]
        end
        
        if customer_attrs[:mobile_number].present? && customer_attrs[:mobile_number] != customer.mobile_number
          # Check if this mobile number is already taken by another customer
          existing = merchant.customers.find_by(mobile_number: customer_attrs[:mobile_number])
          if existing && existing.id != customer.id
            raise StandardError, "Mobile number #{customer_attrs[:mobile_number]} is already taken by another customer (#{existing.full_name})"
          end
          update_attrs[:mobile_number] = customer_attrs[:mobile_number]
        end
        
        customer.update!(update_attrs) if update_attrs.present?
        customer
      else
        # Customer doesn't exist - check if mobile number is taken before creating
        if customer_attrs[:mobile_number].present?
          existing = merchant.customers.find_by(mobile_number: customer_attrs[:mobile_number])
          if existing
            raise StandardError, "Mobile number #{customer_attrs[:mobile_number]} is already used by another customer (#{existing.full_name}). Please use a different mobile number or select that customer."
          end
        end
        
        # Create new customer
        merchant.customers.create!(customer_attrs)
      end
    end

    def calculate_delivery_fee(order)
      return 0 if order.in_store? || order.order_items.all? { |item| item.product.digital? }
      50.0 # Default delivery fee
    end

    def calculate_convenience_fee(order)
      10.0 # Default convenience fee
    end

    def send_order_confirmation_email(order, customer_attrs_hash)
      # Determine email to send to - use override email if provided, otherwise customer's stored email
      email_to_send = customer_attrs_hash&.dig(:email) || order.customer.email
      Rails.logger.info "Sending order confirmation email to: #{email_to_send} (customer record: #{order.customer.email})"
      
      begin
        # Try immediate delivery first
        OrderMailer.order_placed(order, email_override: email_to_send).deliver_now
        Rails.logger.info "✅ Order confirmation email sent successfully to #{email_to_send}"
      rescue Net::OpenTimeout, Net::ReadTimeout, Errno::ETIMEDOUT => e
        Rails.logger.warn "⚠️  SMTP timeout for order #{order.id}, skipping background job to avoid timing issues"
        Rails.logger.warn "Email can be sent manually or attempted later when order is confirmed"
      rescue => e
        Rails.logger.error "❌ Failed to send order confirmation email: #{e.class}: #{e.message}"
        Rails.logger.error e.backtrace.join("\n")
        # Don't fail the order creation if email fails
      end
    end
  end
end