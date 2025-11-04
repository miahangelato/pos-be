# frozen_string_literal: true

module Types
  class QueryType < Types::BaseObject
    field :node, Types::NodeType, null: true, description: "Fetches an object given its ID." do
      argument :id, ID, required: true, description: "ID of the object."
    end

    def node(id:)
      context.schema.object_from_id(id, context)
    end

    field :nodes, [Types::NodeType, null: true], null: true, description: "Fetches a list of objects given a list of IDs." do
      argument :ids, [ID], required: true, description: "IDs of the objects."
    end

    def nodes(ids:)
      ids.map { |id| context.schema.object_from_id(id, context) }
    end

    # Add root-level fields here.
    # They will be entry points for queries on your schema.

    # Products and Categories queries
    field :products, [Types::ProductType], null: false, description: "Get products based on user role" do
      argument :category_id, ID, required: false, description: "Filter by category ID"
      argument :merchant_id, ID, required: false, description: "Filter by merchant ID (admin only)"
    end

    def products(category_id: nil, merchant_id: nil)
      merchant = context[:current_merchant]
      Rails.logger.info "====== PRODUCTS QUERY DEBUG ======"
      Rails.logger.info "Current merchant: #{merchant.inspect}"
      Rails.logger.info "Merchant role: #{merchant&.role}"
      Rails.logger.info "Is customer?: #{merchant&.customer?}"
      Rails.logger.info "Is merchant?: #{merchant&.merchant?}"
      Rails.logger.info "Is admin?: #{merchant&.admin?}"
      
      return [] unless merchant

      # Customers see ALL products from ALL merchants (marketplace)
      if merchant.customer?
        Rails.logger.info "CUSTOMER BRANCH - Loading ALL products"
        products = Product.includes(:category, :merchant).all
        Rails.logger.info "Products count: #{products.count}"
      # Admins can filter by merchant or see all products
      elsif merchant.admin?
        Rails.logger.info "ADMIN BRANCH"
        products = merchant_id.present? ? Product.includes(:category, :merchant).where(merchant_id: merchant_id) : Product.includes(:category, :merchant).all
        Rails.logger.info "Products count: #{products.count}"
      # Merchants see only their own products
      else
        Rails.logger.info "MERCHANT BRANCH - Loading merchant's products only"
        products = merchant.products.includes(:category)
        Rails.logger.info "Products count: #{products.count}"
      end
      
      products = products.by_category(category_id) if category_id.present?
      Rails.logger.info "Final products count: #{products.count}"
      Rails.logger.info "=================================="
      products
    end

    field :categories, [Types::CategoryType], null: false, description: "Get all categories for the authenticated merchant"

    def categories
      # Categories are global and shared across merchants. Return the
      # full list (ordered by name) so every merchant can pick from them
      # when creating products.
      Category.order(:name)
    end

    field :product, Types::ProductType, null: true, description: "Get a single product by ID" do
      argument :id, ID, required: true, description: "Product ID"
    end

    def product(id:)
      merchant = context[:current_merchant]
      return nil unless merchant

      # Customers can view any product (marketplace)
      if merchant.customer?
        Product.find_by(id: id)
      # Admins can view any product
      elsif merchant.admin?
        Product.find_by(id: id)
      # Merchants can only view their own products
      else
        Product.find_by(id: id, merchant_id: merchant.id)
      end
    end

    # Orders queries
    field :orders, [Types::OrderType], null: false, description: "Get all orders for the authenticated user" do
      argument :status, String, required: false, description: "Filter by status (PENDING, CONFIRMED, COMPLETED)"
      argument :merchant_id, ID, required: false, description: "Filter by merchant ID (admin only)"
    end

    def orders(status: nil, merchant_id: nil)
      merchant = context[:current_merchant]
      return [] unless merchant

      # If user is a customer, show orders where customer email matches
      if merchant.customer?
        orders = Order.joins(:customer).where(customers: { email: merchant.email })
      # If user is an admin, show all orders or filter by merchant_id
      elsif merchant.admin?
        orders = merchant_id.present? ? Order.where(merchant_id: merchant_id) : Order.all
      # If user is a merchant, show orders containing their products
      else
        # Orders where the merchant_id matches (orders created for this merchant's products)
        orders = merchant.orders
      end
      
      orders = orders.includes(:customer, :order_items, :delivery_address)
      orders = orders.by_status(status) if status.present?
      orders.recent
    end

    field :order, Types::OrderType, null: true, description: "Get a single order by ID" do
      argument :id, ID, required: true, description: "Order ID"
    end

    def order(id:)
      merchant = context[:current_merchant]
      return nil unless merchant

      # If user is a customer, only show orders where customer email matches
      if merchant.customer?
        Order.joins(:customer).where(customers: { email: merchant.email }).find_by(id: id)
      else
        # For merchants and admins, show their merchant's orders
        merchant.orders.find_by(id: id)
      end
    end

    # Customers queries
    field :customers, [Types::CustomerType], null: false, description: "Get all customers for the authenticated merchant" do
      argument :query, String, required: false, description: "Search query for email or mobile"
    end

    def customers(query: nil)
      merchant = context[:current_merchant]
      return [] unless merchant

      customers = merchant.customers
      if query.present?
        customers = customers.where(
          "email ILIKE ? OR mobile_number ILIKE ? OR first_name ILIKE ? OR last_name ILIKE ?",
          "%#{query}%", "%#{query}%", "%#{query}%", "%#{query}%"
        )
      end
      customers.order(:first_name, :last_name)
    end

    # Admin users management
    field :users, [Types::MerchantType], null: false, description: "Get all users (merchants and customers) - admin only" do
      argument :role, String, required: false, description: "Filter by role (CUSTOMER, MERCHANT, ADMIN)"
      argument :query, String, required: false, description: "Search query for name or email"
    end

    def users(role: nil, query: nil)
      merchant = context[:current_merchant]
      return [] unless merchant&.admin?

      users = Merchant.all
      users = users.where(role: role) if role.present?
      
      if query.present?
        users = users.where(
          "name ILIKE ? OR email ILIKE ?",
          "%#{query}%", "%#{query}%"
        )
      end
      
      users.order(:name)
    end
  end
end
