

class Auth::SessionsController < DeviseTokenAuth::SessionsController
  # Overriding the create action to implement OTP-based login
  def create
    user = User.find_by(email: params[:email])

    if user&.valid_password?(params[:password])
      # Set OTP requirement only if not already set and send OTP
      if user.set_otp_required && send_otp(user)
        render json: { message: "OTP sent successfully. Please verify it." }, status: :ok
      else
        render json: { error: 'Failed to send OTP. Please try again.' }, status: :internal_server_error
      end
    else
      render json: { errors: ['Invalid login credentials'] }, status: :unauthorized
    end
  end

  # # Action to verify OTP and complete login
  # def verify_otp
  #   user = User.find_by(email: params[:email])
  
  #   if user && user.valid_otp?(params[:otp])  # Assuming you have a method to validate the OTP
  #     # Log the user in or perform any necessary actions
  #     render json: { message: 'OTP verified successfully!' }, status: :ok
  #   else
  #     render json: { error: 'Invalid OTP.' }, status: :unauthorized
  #   end
  # end
  def verify_otp
    user = User.find_by(email: params[:email])
  
    if user && user.valid_otp?(params[:otp])  # Assuming you have a method to validate the OTP
      # OTP verified, generate a token
      token = user.create_new_auth_token
  
      # Send the token in the response headers
      response.headers.merge!(token)  # Add the token to the response headers
      render json: { message: 'OTP verified successfully!' }, status: :ok
    else
      render json: { error: 'Invalid OTP.' }, status: :unauthorized
    end
  end
  
  

  def resend_otp
    user = User.find_by(email: params[:email])
    if user
      if send_otp(user)
        render json: { message: "OTP resent successfully." }, status: :ok
      else
        render json: { error: "Failed to send OTP." }, status: :internal_server_error
      end
    else
      render json: { error: "User not found." }, status: :not_found
    end
  end
  
  def employee_login
    # Fetch the employee user from the database
    user = User.find_by(email: params[:email])

    # Check if the user exists, if the password is correct, and if the role is 'employee'
    if user && user.valid_password?(params[:password]) && user.role == 'employee'
      # Generate an auth token for the employee
      token = user.create_new_auth_token

      # Send the token in the response headers
      response.headers.merge!(token)

      # Respond with success
      render json: { message: 'Employee logged in successfully!' }, status: :ok
    else
      # Return an error if the credentials are invalid or the user is not an employee
      render json: { error: 'Invalid credentials or user is not an employee.' }, status: :unauthorized
    end
  end

  private


  

  # Method to send OTP to the user’s email
  def send_otp(user)
    begin
      user.send_new_otp # This method sends the OTP email
      Rails.logger.info "OTP sent to #{user.email}" # Log the OTP for debugging
      true
    rescue StandardError => e
      Rails.logger.error "Error sending OTP to #{user.email}: #{e.message}"
      false
    end
  end
end
