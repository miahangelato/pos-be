# frozen_string_literal: true

require_relative '../../services/jwt_token_service'

module Mutations
  class SignUp < BaseMutation
    argument :first_name, String, required: true, description: "First name"
    argument :last_name, String, required: true, description: "Last name"
    argument :email, String, required: true, description: "Email address"
    argument :password, String, required: true, description: "Password"
    argument :role, String, required: false, description: "User role (CUSTOMER or MERCHANT), defaults to MERCHANT"

    field :merchant, Types::MerchantType, null: true, description: "The created merchant (user)"
    field :token, String, null: true, description: "Authentication token"
    field :errors, [String], null: false, description: "Validation errors"

    def resolve(first_name:, last_name:, email:, password:, role: 'MERCHANT')
      # Validate inputs
      errors = validate_inputs(first_name, last_name, email, password, role)
      return { merchant: nil, token: nil, errors: errors } if errors.any?

      # Create merchant (user) with specified role
      merchant = Merchant.new(
        name: "#{first_name} #{last_name}",
        email: email,
        password: password,
        role: role.upcase,
        active: true
      )

      if merchant.save
        # Generate JWT token
        token = generate_token(merchant)

        {
          merchant: merchant,
          token: token,
          errors: []
        }
      else
        {
          merchant: nil,
          token: nil,
          errors: merchant.errors.full_messages
        }
      end
    end

    private

    def validate_inputs(first_name, last_name, email, password, role)
      errors = []

      errors << "First name is required" if first_name.blank?
      errors << "Last name is required" if last_name.blank?
      errors << "Email is required" if email.blank?
      errors << "Invalid email format" if email.present? && !email.match?(URI::MailTo::EMAIL_REGEXP)
      errors << "Password is required" if password.blank?
      errors << "Password must be at least 8 characters" if password.present? && password.length < 8
      errors << "Email already exists" if Merchant.exists?(email: email)
      
      valid_roles = %w[CUSTOMER MERCHANT ADMIN]
      errors << "Invalid role. Must be one of: #{valid_roles.join(', ')}" unless valid_roles.include?(role.upcase)

      errors
    end

    def generate_token(merchant)
      JwtTokenService.generate(merchant.id)
    end
  end
end
