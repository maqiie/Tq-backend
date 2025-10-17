require 'rotp'

class User < ActiveRecord::Base
  devise :registerable,
         :recoverable, :rememberable, :validatable,
         :confirmable, :two_factor_authenticatable,
         otp_secret_encryption_key: ENV['OTP_SECRET_ENCRYPTION_KEY']
  
  include DeviseTokenAuth::Concerns::User
  
  # Associations
  has_many :agents, dependent: :destroy  # Agents owned by this user (if admin)
  has_many :transactions, through: :agents
  
  # Multi-tenancy: Admin can have many employees, Employee belongs to one admin
  has_many :employees, class_name: 'User', foreign_key: 'admin_id', dependent: :nullify
  belongs_to :admin, class_name: 'User', foreign_key: 'admin_id', optional: true
  
  # Roles
  enum role: { admin: 0, employee: 1 }
  after_initialize :set_default_role, if: :new_record?
  
  # Callbacks
  before_create :generate_otp_secret, unless: :otp_secret?
  
  # Check if user is an admin
  def admin?
    role == 'admin'
  end
  
  # Get accessible agents based on role (multi-tenancy)
  def accessible_agents
    case role
    when 'admin'
      agents  # Admins see only their own agents
    when 'employee'
      admin.present? ? admin.agents : Agent.none  # Employees see their admin's agents
    else
      Agent.none
    end
  end
  
  # Send OTP via email
  def send_new_otp
    otp_code = current_otp
    Rails.logger.info "Sending OTP email to: #{email}, OTP code: #{otp_code}"
    UserMailer.otp_email(self, otp_code).deliver_now
  end
  
  # Generate the current OTP
  def current_otp
    ROTP::TOTP.new(otp_secret).now
  end
  
  # Validate the provided OTP
  def valid_otp?(otp)
    Rails.logger.info "Verifying OTP: #{otp}, Expected OTP: #{current_otp}"
    ROTP::TOTP.new(otp_secret).verify(otp, drift_behind: 60)
  end
  
  # Enable OTP requirement for login
  def set_otp_required
    update_column(:otp_required_for_login, true)
  end
  
  # Send password reset instructions
  def send_reset_password_instructions
    generate_reset_password_token
    UserMailer.reset_password_instructions(self, reset_password_token).deliver_now
  end
  
  private
  
  # Set default role to 'employee'
  def set_default_role
    self.role ||= 'employee'
  end
  
  # Generate a new OTP secret if not present
  def generate_otp_secret
    return if otp_secret.present?
    self.otp_secret = ROTP::Base32.random_base32
    self.otp_required_for_login = true
    Rails.logger.info "Generated OTP secret for user: #{email}, OTP secret: #{otp_secret}"
  end
  
  # Generate a reset password token
  def generate_reset_password_token
    self.reset_password_token = Devise.friendly_token
    self.reset_password_sent_at = Time.now.utc
    if save
      Rails.logger.info "Generated reset password token for user: #{email}, Token: #{reset_password_token}"
    else
      Rails.logger.error "Failed to generate reset password token for user: #{email}, Errors: #{errors.full_messages.join(', ')}"
    end
  end
end

# require 'rotp'

# class User < ActiveRecord::Base
#   devise :registerable,
#          :recoverable, :rememberable, :validatable,
#          :confirmable, :two_factor_authenticatable,
#          otp_secret_encryption_key: ENV['OTP_SECRET_ENCRYPTION_KEY']

#   include DeviseTokenAuth::Concerns::User

#   # Associations
#   has_many :agents
#   has_many :transactions, through: :agents

#   # Roles
#   enum role: { admin: 0, employee: 1 }
#   after_initialize :set_default_role, if: :new_record?

#   # Callbacks
#   before_create :generate_otp_secret, unless: :otp_secret?

#   # Check if user is an admin
#   def admin?
#     role == 'admin'
#   end

#   # Send OTP via email
#   def send_new_otp
#     otp_code = current_otp
#     Rails.logger.info "Sending OTP email to: #{email}, OTP code: #{otp_code}"
#     UserMailer.otp_email(self, otp_code).deliver_now
#   end

#   # Generate the current OTP
#   def current_otp
#     ROTP::TOTP.new(otp_secret).now
#   end

#   # Validate the provided OTP
#   def valid_otp?(otp)
#     Rails.logger.info "Verifying OTP: #{otp}, Expected OTP: #{current_otp}"
#     ROTP::TOTP.new(otp_secret).verify(otp, drift_behind: 60)
#   end

#   # Enable OTP requirement for login
#   def set_otp_required
#     update_column(:otp_required_for_login, true)
#   end

#   # Send password reset instructions
#   def send_reset_password_instructions
#     generate_reset_password_token # Set the token
#     UserMailer.reset_password_instructions(self, reset_password_token).deliver_now
#   end

#   private

#   # Set default role to 'employee'
#   def set_default_role
#     self.role ||= 'employee'
#   end

#   # Generate a new OTP secret if not present
#   def generate_otp_secret
#     return if otp_secret.present?

#     self.otp_secret = ROTP::Base32.random_base32
#     self.otp_required_for_login = true
#     Rails.logger.info "Generated OTP secret for user: #{email}, OTP secret: #{otp_secret}"
#   end

#   # Generate a reset password token
#   def generate_reset_password_token
#     self.reset_password_token = Devise.friendly_token
#     self.reset_password_sent_at = Time.now.utc
#     if save
#       Rails.logger.info "Generated reset password token for user: #{email}, Token: #{reset_password_token}"
#     else
#       Rails.logger.error "Failed to generate reset password token for user: #{email}, Errors: #{errors.full_messages.join(', ')}"
#     end
#   end
# end
