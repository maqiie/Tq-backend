class Auth::PasswordsController < Devise::PasswordsController
  before_action :configure_permitted_parameters, only: [:create, :update]


  def update
    self.resource = resource_class.find_by(reset_password_token: params[:user][:reset_password_token])
  
    if resource.present? && resource.reset_password(params[:user][:password], params[:user][:password_confirmation])
      render json: { message: "Password reset successfully." }, status: :ok
    else
      render json: { errors: resource.errors.full_messages.presence || ["Invalid token or password mismatch."] }, status: :unprocessable_entity
    end
  end
  # Action to request a password reset
  def create
    self.resource = resource_class.find_by(email: resource_params[:email])

    if resource.present?
      # Send reset password instructions
      resource.send_reset_password_instructions
      render json: { message: "Password reset instructions sent." }, status: :ok
    else
      render json: { errors: ["Email not found."] }, status: :unprocessable_entity
    end
  end

 
  
  private

  # Permitting additional parameters for password reset
  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:create, keys: [:email])
    devise_parameter_sanitizer.permit(:update, keys: [:password, :password_confirmation, :reset_password_token])
  end

  # Ensuring correct format for resource params
  def resource_params
    params.require(:user).permit(:email)
  end
end
