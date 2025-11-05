# frozen_string_literal: true

module Mutations
  class UpdateProduct < BaseMutation
    argument :id, ID, required: true, description: "Product ID"
    argument :name, String, required: false, description: "Product name"
    argument :description, String, required: false, description: "Product description"
    argument :price, Float, required: false, description: "Product price"
    argument :product_type, String, required: false, description: "Product type (PHYSICAL or DIGITAL)"
    argument :stock_quantity, Integer, required: false, description: "Stock quantity for physical products"
    argument :category_id, ID, required: false, description: "Category ID"
    argument :image_url, String, required: false, description: "Image URL"

    field :product, Types::ProductType, null: true, description: "The updated product"
    field :errors, [String], null: false, description: "Errors if any"

    def resolve(id:, name: nil, description: nil, price: nil, product_type: nil, stock_quantity: nil, category_id: nil, image_url: nil)
      # Get merchant from context (should be authenticated)
      merchant = context[:current_merchant]
      unless merchant
        return {
          product: nil,
          errors: ['You must be authenticated to update a product']
        }
      end

      # Check permission
      unless merchant.can_manage_products?
        return {
          product: nil,
          errors: ['You do not have permission to update products']
        }
      end

      # Find product - admins can update any product, merchants only their own
      if merchant.admin?
        product = Product.find_by(id: id)
      else
        product = Product.find_by(id: id, merchant_id: merchant.id)
      end
      
      unless product
        return {
          product: nil,
          errors: ['Product not found or does not belong to your account']
        }
      end

      # Validate category if provided (categories are global/shared)
      if category_id.present?
        category = Category.find_by(id: category_id)
        unless category
          return {
            product: nil,
            errors: ['Category not found']
          }
        end
      end

      # Build update attributes
      update_attrs = {}
      update_attrs[:name] = name if name.present?
      update_attrs[:description] = description if description.present?
      update_attrs[:price] = price if price.present?
      update_attrs[:product_type] = product_type.upcase if product_type.present?
      update_attrs[:stock_quantity] = stock_quantity if stock_quantity.present?
      update_attrs[:category_id] = category_id if category_id.present?

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
            update_attrs[:image_data] = image_data
            update_attrs[:image_content_type] = content_type
            update_attrs[:image_filename] = "product_image.#{content_type.split('/').last}"
          end
        rescue => e
          Rails.logger.error "Error processing image data: #{e.message}"
          # Continue without image rather than failing the entire product update
        end
      elsif image_url.present?
        # Handle regular image URL (for backward compatibility)
        update_attrs[:image_url] = image_url
      end

      if product.update(update_attrs)
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
