class Category < ApplicationRecord
  # Associations
  has_many :products, dependent: :nullify

  # Validations
  validates :name, presence: true, uniqueness: true
end
