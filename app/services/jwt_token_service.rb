# frozen_string_literal: true

class JwtTokenService
  EXPIRATION_TIME = 7.days.from_now.to_i

  class TokenError < StandardError; end

  def self.secret_key
    Rails.application.key_generator.generate_key('jwt_secret')
  end

  def self.generate(merchant_id)
    payload = {
      merchant_id: merchant_id,
      exp: EXPIRATION_TIME
    }

    JWT.encode(payload, secret_key, 'HS256')
  end

  def self.decode(token)
    JWT.decode(token, secret_key, true, algorithm: 'HS256')[0]
  rescue JWT::DecodeError, JWT::ExpiredSignature => e
    raise TokenError, "Invalid token: #{e.message}"
  end

  def self.valid?(token)
    decode(token)
    true
  rescue TokenError
    false
  end
end
