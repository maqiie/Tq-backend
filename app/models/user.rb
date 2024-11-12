
require 'rotp'

class User < ActiveRecord::Base
  devise :registerable,
         :recoverable, :rememberable, :validatable,
         :confirmable, :two_factor_authenticatable,
         otp_secret_encryption_key: ENV['OTP_SECRET_ENCRYPTION_KEY']

  include DeviseTokenAuth::Concerns::User

  before_create :generate_otp_secret, unless: :otp_secret?
  has_many :agents
  has_many :transactions, through: :agents


  # Add enum for role (admin and employee)
  enum role: { admin: 0, employee: 1 }

  before_create :generate_otp_secret, unless: :otp_secret?

  # Role validation
  validates :role, inclusion: { in: roles.keys } # Automatically ensures valid roles

  after_initialize :set_default_role, if: :new_record?


  # Check if user is an admin
  def admin?
    role == 'admin'
  end

  # Send OTP via email
  def send_new_otp
    otp_code = current_otp
    Rails.logger.info "Sending OTP email to: #{email}, OTP code: #{otp_code}"
    
    UserMailer.otp_email(self, otp_code).deliver_now
  end
  
  # Generate the current OTP based on the user's OTP secret
  def current_otp
    ROTP::TOTP.new(otp_secret).now
  end
  
  # Validate the provided OTP against the generated current OTP
  def valid_otp?(otp)
    Rails.logger.info "Verifying OTP: #{otp}, Expected OTP: #{current_otp}"
    ROTP::TOTP.new(otp_secret).verify(otp, drift_behind: 60)
  end

  # Method to set the OTP requirement for login
  def set_otp_required
    update_column(:otp_required_for_login, true)
  end

  # Method to send password reset instructions
  # 
  def send_reset_password_instructions
    generate_reset_password_token # Ensure this method is called to set the token
    UserMailer.reset_password_instructions(self, reset_password_token).deliver_now
  end
  
  

  private
  

  def set_default_role
    self.role ||= 'employee' # Default to 'employee'
  end  

  # Generate a new OTP secret if it does not already exist
  def generate_otp_secret
    return if otp_secret.present?
  
    self.otp_secret = ROTP::Base32.random_base32
    self.otp_required_for_login = true
    # save!
    Rails.logger.info "Generated OTP secret for user: #{email}, OTP secret: #{otp_secret}"
  end

  # Generate a reset password token
  def generate_reset_password_token
    self.reset_password_token = Devise.friendly_token
    self.reset_password_sent_at = Time.now.utc
    if save!
      Rails.logger.info "Generated reset password token for user: #{email}, Token: #{reset_password_token}"
    else
      Rails.logger.error "Failed to generate reset password token for user: #{email}, Errors: #{errors.full_messages.join(", ")}"
    end
  end
  
  
end
