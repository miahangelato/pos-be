# frozen_string_literal: true

module Mutations
  class UpdateUser < BaseMutation
    description "Update a user - Admin only"

    # Input fields
    argument :id, ID, required: true
    argument :name, String, required: false
    argument :email, String, required: false
    argument :password, String, required: false
    argument :role, String, required: false
    argument :active, Boolean, required: false

    # Return fields
    field :user, Types::MerchantType, null: true
    field :errors, [String], null: false

    def resolve(id:, **attributes)
      # Check if current user is admin
      unless context[:current_merchant]&.admin?
        return {
          user: nil,
          errors: ["Only admins can update users"]
        }
      end

      user = Merchant.find_by(id: id)
      unless user
        return {
          user: nil,
          errors: ["User not found"]
        }
      end

      # Validate role if provided
      if attributes[:role].present? && !['CUSTOMER', 'MERCHANT', 'ADMIN'].include?(attributes[:role])
        return {
          user: nil,
          errors: ["Invalid role. Must be CUSTOMER, MERCHANT, or ADMIN"]
        }
      end

      # Remove password if empty (don't update password if not provided)
      attributes.delete(:password) if attributes[:password].blank?

      if user.update(attributes)
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
