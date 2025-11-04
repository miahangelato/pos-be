# frozen_string_literal: true

module Mutations
  class DeleteUser < BaseMutation
    description "Delete a user - Admin only"

    # Input fields
    argument :id, ID, required: true

    # Return fields
    field :success, Boolean, null: false
    field :errors, [String], null: false

    def resolve(id:)
      # Check if current user is admin
      unless context[:current_merchant]&.admin?
        return {
          success: false,
          errors: ["Only admins can delete users"]
        }
      end

      user = Merchant.find_by(id: id)
      unless user
        return {
          success: false,
          errors: ["User not found"]
        }
      end

      # Prevent admin from deleting themselves
      if user.id == context[:current_merchant].id
        return {
          success: false,
          errors: ["You cannot delete your own account"]
        }
      end

      if user.destroy
        {
          success: true,
          errors: []
        }
      else
        {
          success: false,
          errors: user.errors.full_messages
        }
      end
    end
  end
end
