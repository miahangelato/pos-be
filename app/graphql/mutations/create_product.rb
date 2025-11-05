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
        merchant_id: merchant.id
      )

      # Handle image data URL if provided
      if image_url.present? && image_url.start_with?('data:')
        begin
          # Parse data URL: data:image/jpeg;base64,/9j/4AAQSkZJRgABAQEAYABgAAD...
          match = image_url.match(/\Adata:([^;]+);base64,(.+)\z/)
          if match
            content_type = match[1]
            base64_data = match[2]
            image_data = Base64.decode64(base64_data)
            
            # Store image data in database
            product.image_data = image_data
            product.image_content_type = content_type
            product.image_filename = "product_image.#{content_type.split('/').last}"
          end
        rescue => e
          Rails.logger.error "Error processing image data: #{e.message}"
          # Continue without image rather than failing the entire product creation
        end
      end

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
