module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_user

    def connect
      self.current_user = find_verified_user
      reject_unauthorized_connection unless current_user
    end

    private

    def find_verified_user
      # Try JWT authentication first (for API clients)
      if (token = request.params[:token])
        verified_user_from_jwt(token)
      # Fall back to Warden session auth (for browser clients)
      elsif env["warden"]
        env["warden"].user
      end
    end

    def verified_user_from_jwt(token)
      payload = JsonWebToken.decode(token)
      User.find_by(id: payload[:user_id])
    rescue JWT::DecodeError => e
      Rails.logger.warn("WebSocket JWT decode error: #{e.message}")
      nil
    end
  end
end
