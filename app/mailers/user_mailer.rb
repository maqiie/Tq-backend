class UserMailer < ApplicationMailer
  default from: 'noreply@example.com'

  def otp_email(user, otp_code)
    @user = user
    @otp_code = otp_code
    mail(to: @user.email, subject: 'Your OTP Code')
  end
  def reset_password_instructions(user, token)
    @resource = user
    @reset_password_token = token
    mail(to: @resource.email, subject: 'Reset Your Password') do |format|
      format.html { render 'devise/mailer/reset_password_instructions' }
    end
  end
end
