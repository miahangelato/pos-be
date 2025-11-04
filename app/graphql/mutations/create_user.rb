# frozen_string_literal: true

module Mutations
  class CreateUser < BaseMutation
    description "Create a new user (customer or merchant) - Admin only"

    # Input fields
    argument :name, String, required: true
    argument :email, String, required: true
    argument :password, String, required: true
    argument :role, String, required: true
    argument :active, Boolean, required: false

    # Return fields
    field :user, Types::MerchantType, null: true
    field :errors, [String], null: false

    def resolve(name:, email:, password:, role:, active: true)
      # Check if current user is admin
      unless context[:current_merchant]&.admin?
        return {
          user: nil,
          errors: ["Only admins can create users"]
        }
      end

      # Validate role
      unless ['CUSTOMER', 'MERCHANT', 'ADMIN'].include?(role)
        return {
          user: nil,
          errors: ["Invalid role. Must be CUSTOMER, MERCHANT, or ADMIN"]
        }
      end

      # Create user
      user = Merchant.new(
        name: name,
        email: email,
        password: password,
        role: role,
        active: active
      )

      if user.save
        {
          user: user,
          errors: []
        }
      else
        {
          user: nil,
          errors: user.errors.full_messages
        }
      end
    end
  end
end
