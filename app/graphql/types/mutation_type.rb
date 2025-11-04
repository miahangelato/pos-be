# frozen_string_literal: true

module Types
  class MutationType < Types::BaseObject
    field :sign_up, mutation: Mutations::SignUp, description: "Sign up a new merchant (user)"
    field :sign_in, mutation: Mutations::SignIn, description: "Sign in with email and password"
    field :create_product, mutation: Mutations::CreateProduct, description: "Create a new product"
    field :update_product, mutation: Mutations::UpdateProduct, description: "Update an existing product"
    field :delete_product, mutation: Mutations::DeleteProduct, description: "Delete a product"
    field :create_category, mutation: Mutations::CreateCategory, description: "Create a new category"
    field :create_order, mutation: Mutations::CreateOrder, description: "Create a new order"
    field :place_customer_order, mutation: Mutations::PlaceCustomerOrder, description: "Place an order as a customer (marketplace checkout)"
    field :update_order_status, mutation: Mutations::UpdateOrderStatus, description: "Update order status"
    field :update_payment_status, mutation: Mutations::UpdatePaymentStatus, description: "Update order payment status"
    field :cancel_order, mutation: Mutations::CancelOrder, description: "Cancel an order - Customers can cancel pending orders"
    field :search_customers, mutation: Mutations::SearchCustomers, description: "Search customers by email or mobile number"
    
    # Admin user management
    field :create_user, mutation: Mutations::CreateUser, description: "Create a new user - Admin only"
    field :update_user, mutation: Mutations::UpdateUser, description: "Update a user - Admin only"
    field :delete_user, mutation: Mutations::DeleteUser, description: "Delete a user - Admin only"
  end
end
