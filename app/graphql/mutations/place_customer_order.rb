module Mutations
  class PlaceCustomerOrder < BaseMutation
    description "Place an order as a customer (marketplace checkout)"

    # Arguments
    argument :customer_attributes, Types::CustomerInputType, required: true
    argument :order_items, [Types::OrderItemInputType], required: true
    argument :payment_method, String, required: true
    argument :shipping_method, String, required: true
    argument :delivery_address_attributes, Types::DeliveryAddressInputType, required: true

    # Return fields
    field :orders, [Types::OrderType], null: true
    field :errors, [String], null: false

    def resolve(customer_attributes:, order_items:, payment_method:, shipping_method:, delivery_address_attributes:)
      # Ensure user is authenticated
      current_user = context[:current_user]
      return { orders: nil, errors: ["Authentication required"] } unless current_user

      # Only customers can use this mutation
      unless current_user.customer?
        return { orders: nil, errors: ["This endpoint is for customers only. Merchants should use createOrder mutation."] }
      end

      begin
        created_orders = []
        
        ActiveRecord::Base.transaction do
          # Convert GraphQL input objects to hashes
          customer_attrs_hash = customer_attributes.to_h
          delivery_address_attrs_hash = delivery_address_attributes.to_h
          order_items_hash = order_items.map(&:to_h)

          # Group order items by merchant_id (from products)
          items_by_merchant = {}
          order_items_hash.each do |item_data|
            product = Product.find_by(id: item_data[:product_id])
            
            unless product
              raise "Product with ID #{item_data[:product_id]} not found"
            end

            merchant_id = product.merchant_id
            items_by_merchant[merchant_id] ||= []
            items_by_merchant[merchant_id] << {
              product: product,
              quantity: item_data[:quantity]
            }
          end

          # Create separate order for each merchant
          items_by_merchant.each do |merchant_id, items|
            merchant = Merchant.find(merchant_id)

            # Find or create customer record for this merchant
            # Use the customer's email from their account
            customer = merchant.customers.find_or_create_by!(email: current_user.email) do |c|
              c.first_name = customer_attrs_hash[:first_name]
              c.last_name = customer_attrs_hash[:last_name]
              c.mobile_number = customer_attrs_hash[:mobile_number]
            end

            # Calculate order totals for this merchant's products
            subtotal = items.sum { |item| item[:product].price * item[:quantity] }
            shipping_fee = 50.0 # You can make this dynamic based on shipping_method
            convenience_fee = 10.0
            grand_total = subtotal + shipping_fee + convenience_fee

            # Generate reference number
            reference_number = "ORD-#{Time.now.to_i}-#{SecureRandom.hex(3).upcase}"

            # Create order for this merchant
            order = Order.new(
              merchant: merchant,
              customer: customer,
              order_type: 'ONLINE',
              payment_method: payment_method,
              shipping_method: shipping_method,
              status: 'PENDING',
              payment_status: 'PENDING',
              reference_number: reference_number,
              subtotal: subtotal,
              shipping_fee: shipping_fee,
              convenience_fee: convenience_fee,
              grand_total: grand_total
            )

            unless order.save
              raise "Failed to create order: #{order.errors.full_messages.join(', ')}"
            end

            # Create delivery address
            delivery_address = DeliveryAddress.new(
              order: order,
              province: delivery_address_attrs_hash[:province],
              city: delivery_address_attrs_hash[:city],
              barangay: delivery_address_attrs_hash[:barangay],
              street: delivery_address_attrs_hash[:street],
              room_unit: delivery_address_attrs_hash[:unit_floor], # Map unit_floor to room_unit
              building: delivery_address_attrs_hash[:building_name], # Map building_name to building
              landmark: delivery_address_attrs_hash[:landmark],
              remarks: delivery_address_attrs_hash[:remarks]
            )

            unless delivery_address.save
              raise "Failed to create delivery address: #{delivery_address.errors.full_messages.join(', ')}"
            end

            # Create order items for this merchant's products
            items.each do |item_data|
              product = item_data[:product]
              quantity = item_data[:quantity]

              order_item = OrderItem.new(
                order: order,
                product: product,
                quantity: quantity,
                price_at_purchase: product.price
              )

              unless order_item.save
                raise "Failed to create order item: #{order_item.errors.full_messages.join(', ')}"
              end

              # Update product stock for physical products
              if product.physical? && product.stock_quantity.present?
                new_stock = product.stock_quantity - quantity
                if new_stock < 0
                  raise "Insufficient stock for product: #{product.name}"
                end
                product.update!(stock_quantity: new_stock)
              end
            end

            created_orders << order
          end
        end

        { orders: created_orders, errors: [] }
      rescue => e
        { orders: nil, errors: [e.message] }
      end
    end
  end
end
