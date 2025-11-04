# frozen_string_literal: true

module Api
  class ProductsController < ApplicationController
    before_action :authenticate_merchant!
    before_action :set_product, only: [:image]

    # POST/PATCH/PUT /api/products/:id/image
    def image
      if @product.update(image_params)
        render json: { success: true, message: 'Image uploaded successfully' }
      else
        render json: { error: @product.errors.full_messages.join(', ') }, status: :unprocessable_entity
      end
    end

    private

    def set_product
      @product = Product.find_by(id: params[:id], merchant_id: current_merchant.id)
      return render json: { error: 'Product not found' }, status: :not_found unless @product
    end

    def image_params
      # Frontend sends image directly as 'image' parameter, not nested under 'product'
      { image: params[:image] } if params.key?(:image)
    end

    def authenticate_merchant!
      token = request.headers['Authorization']&.split(' ')&.last
      decoded = JwtTokenService.decode(token) if token
      @current_merchant = Merchant.find_by(id: decoded['merchant_id']) if decoded
      return render json: { error: 'Unauthorized' }, status: :unauthorized unless @current_merchant
    end

    def current_merchant
      @current_merchant
    end
  end
end
