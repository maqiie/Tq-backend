class Auth::PasswordsController < Devise::PasswordsController
  # Override the create action
  def create
    params[:redirect_url] = params[:redirect_url] if params[:redirect_url].present?
    super
  end

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:reset_password, keys: [:email, :redirect_url])
    devise_parameter_sanitizer.permit(:create, keys: [:email])
  end

  # Override the update method
  def update
    self.resource = resource_class.find_by(reset_password_token: params[:user][:reset_password_token])
    
    if resource.nil?
      Rails.logger.error("Invalid reset password token provided.")
      return render :edit, status: :unprocessable_entity
    end

    if resource.update(resource_params)
      sign_in(resource)
      redirect_to after_password_reset_path
    else
      Rails.logger.error("Password update failed: #{resource.errors.full_messages.join(', ')}")
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def resource_params
    params.require(:user).permit(:reset_password_token, :password, :password_confirmation, :email)
  end

  def after_password_reset_path
    root_path
  end
end
