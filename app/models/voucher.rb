class Voucher < ApplicationRecord
  # Associations
  belongs_to :merchant

  # Validations
  validates :code, presence: true, uniqueness: { scope: :merchant_id }
  validates :merchant_id, presence: true
  validates :active, inclusion: { in: [true, false] }
  validate :discount_type_present
  validate :expires_at_in_future, if: :expires_at

  # Scopes
  scope :active, -> { where(active: true) }
  scope :valid, -> { active.where('expires_at IS NULL OR expires_at > ?', Time.current) }
  scope :by_code, ->(code) { where('code ILIKE ?', code) }

  def valid?
    active? && (expires_at.nil? || expires_at > Time.current) && usage_available?
  end

  def usage_available?
    max_uses.nil? || current_uses < max_uses
  end

  def discount_value
    if discount_percentage.present?
      discount_percentage
    elsif discount_amount.present?
      discount_amount
    end
  end

  def use_voucher
    return false unless valid?
    update(current_uses: current_uses + 1)
  end

  private

  def discount_type_present
    if discount_percentage.blank? && discount_amount.blank?
      errors.add(:base, 'Either discount percentage or discount amount must be present')
    end
  end

  def expires_at_in_future
    if expires_at <= Time.current
      errors.add(:expires_at, 'must be in the future')
    end
  end
end
