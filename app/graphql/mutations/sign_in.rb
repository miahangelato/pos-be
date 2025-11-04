# frozen_string_literal: true

require_relative '../../services/jwt_token_service'

module Mutations
  class SignIn < BaseMutation
    argument :email, String, required: true, description: "Email address"
    argument :password, String, required: true, description: "Password"

    field :merchant, Types::MerchantType, null: true, description: "The authenticated merchant (user)"
    field :token, String, null: true, description: "Authentication token"
    field :errors, [String], null: false, description: "Authentication errors"

    def resolve(email:, password:)
      errors = []

      # Validate inputs
      errors << "Email is required" if email.blank?
      errors << "Password is required" if password.blank?

      return { merchant: nil, token: nil, errors: errors } if errors.any?

      # Find merchant by email
      merchant = Merchant.find_by(email: email)

      if merchant.nil?
        return {
          merchant: nil,
          token: nil,
          errors: ["Invalid email or password"]
        }
      end

      # Check if merchant is active
      unless merchant.active?
        return {
          merchant: nil,
          token: nil,
          errors: ["Account is inactive"]
        }
      end

      # Verify password with bcrypt
      unless merchant.authenticate(password)
        return {
          merchant: nil,
          token: nil,
          errors: ["Invalid email or password"]
        }
      end

      # Generate JWT token
      token = generate_token(merchant)

      {
        merchant: merchant,
        token: token,
        errors: []
      }
    end

    private

    def generate_token(merchant)
      JwtTokenService.generate(merchant.id)
    end
  end
end
