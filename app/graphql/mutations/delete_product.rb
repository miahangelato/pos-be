# frozen_string_literal: true

module Mutations
  class DeleteProduct < BaseMutation
    argument :id, ID, required: true, description: "Product ID"

    field :success, Boolean, null: false, description: "Whether the product was deleted"
    field :errors, [String], null: false, description: "Errors if any"

    def resolve(id:)
      # Get merchant from context (should be authenticated)
      merchant = context[:current_merchant]
      unless merchant
        return {
          success: false,
          errors: ['You must be authenticated to delete a product']
        }
      end

      # Check permission
      unless merchant.can_manage_products?
        return {
          success: false,
          errors: ['You do not have permission to delete products']
        }
      end

      # Find product - admins can delete any product, merchants only their own
      if merchant.admin?
        product = Product.find_by(id: id)
      else
        product = Product.find_by(id: id, merchant_id: merchant.id)
      end
      
      unless product
        return {
          success: false,
          errors: ['Product not found or does not belong to your account']
        }
      end

      # Delete the product
      if product.destroy
        {
          success: true,
          errors: []
        }
      else
        {
          success: false,
          errors: product.errors.full_messages
        }
      end
    end
  end
end
