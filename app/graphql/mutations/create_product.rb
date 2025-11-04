# frozen_string_literal: true

module Mutations
  class CreateProduct < BaseMutation
    argument :name, String, required: true, description: "Product name"
    argument :description, String, required: false, description: "Product description"
    argument :price, Float, required: true, description: "Product price"
    argument :product_type, String, required: true, description: "Product type (PHYSICAL or DIGITAL)"
    argument :stock_quantity, Integer, required: false, description: "Stock quantity for physical products"
    argument :category_id, ID, required: true, description: "Category ID"
    argument :image_url, String, required: false, description: "Image URL"

    field :product, Types::ProductType, null: true, description: "The created product"
    field :errors, [String], null: false, description: "Errors if any"

    def resolve(name:, price:, product_type:, category_id:, description: nil, stock_quantity: nil, image_url: nil)
      # Get merchant from context (should be authenticated)
      merchant = context[:current_merchant]
      unless merchant
        return {
          product: nil,
          errors: ['You must be authenticated to create a product']
        }
      end

      # Check permission
      unless merchant.can_manage_products?
        return {
          product: nil,
          errors: ['You do not have permission to create products']
        }
      end

      # Validate category exists (categories are global/shared)
      category = Category.find_by(id: category_id)
      unless category
        return {
          product: nil,
          errors: ['Category not found']
        }
      end

      # Create product
      product = Product.new(
        name: name,
        description: description,
        price: price,
        product_type: product_type.upcase,
        stock_quantity: stock_quantity,
        category_id: category_id,
        merchant_id: merchant.id,
        image_url: image_url
      )

      if product.save
        {
          product: product,
          errors: []
        }
      else
        {
          product: nil,
          errors: product.errors.full_messages
        }
      end
    end
  end
end
