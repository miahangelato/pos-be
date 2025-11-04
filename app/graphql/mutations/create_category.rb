# frozen_string_literal: true

module Mutations
  class CreateCategory < BaseMutation
    argument :name, String, required: true, description: "Category name"

    field :category, Types::CategoryType, null: true, description: "The created category"
    field :errors, [String], null: false, description: "Errors if any"

    def resolve(name:)
      # Get merchant from context (should be authenticated)
      merchant = context[:current_merchant]
      unless merchant
        return {
          category: nil,
          errors: ['You must be authenticated to create a category']
        }
      end

      # Create category
      category = Category.new(
        name: name,
        merchant_id: merchant.id
      )

      if category.save
        {
          category: category,
          errors: []
        }
      else
        {
          category: nil,
          errors: category.errors.full_messages
        }
      end
    end
  end
end
