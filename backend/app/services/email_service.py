"""
Email service for sending OTP and notifications
"""
import os
import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart


class EmailService:
    """
    Email service for OTP delivery and notifications
    Uses SMTP configuration from environment variables
    """
    
    @staticmethod
    def send_otp_email(to_email, otp, display_name=None):
        """
        Send OTP email to user
        
        Args:
            to_email: Recipient email address
            otp: OTP code
            display_name: User's display name (optional)
            
        Returns:
            (success: bool, error_message: str)
        """
        try:
            # Email configuration from environment
            smtp_server = os.getenv('MAIL_SERVER', 'smtp.gmail.com')
            smtp_port = int(os.getenv('MAIL_PORT', 587))
            smtp_username = os.getenv('MAIL_USERNAME')
            smtp_password = os.getenv('MAIL_PASSWORD')
            sender_email = os.getenv('MAIL_DEFAULT_SENDER', 'noreply@hostelixpro.com')
            
            # Skip email in development if not configured
            if not smtp_username or not smtp_password:
                print(f'[DEV MODE] OTP for {to_email}: {otp}')
                return True, None
            
            # Create message
            message = MIMEMultipart('alternative')
            message['Subject'] = 'Hostelix Pro - Login OTP'
            message['From'] = sender_email
            message['To'] = to_email
            
            greeting = f'Hello {display_name},' if display_name else 'Hello,'
            
            # Email body
            text = f"""
{greeting}

Your login verification code for Hostelix Pro is: {otp}

This code will expire in 5 minutes. Do not share this code with anyone.

If you didn't request this code, please change your password immediately.

Best regards,
Hostelix Pro Team
"""
            
            html = f"""
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
</head>
<body style="margin: 0; padding: 0; background-color: #f0f4f8; font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;">
    <table role="presentation" width="100%" cellspacing="0" cellpadding="0" style="max-width: 600px; margin: 0 auto;">
        <!-- Header -->
        <tr>
            <td style="background: linear-gradient(135deg, #1565C0, #0D47A1); padding: 32px 40px; text-align: center; border-radius: 12px 12px 0 0;">
                <h1 style="color: #ffffff; margin: 0; font-size: 26px; font-weight: 700; letter-spacing: 0.5px;">Hostelix<span style="color: #FFB74D;">Pro</span></h1>
                <p style="color: rgba(255,255,255,0.8); margin: 6px 0 0; font-size: 13px;">Enterprise Hostel Management</p>
            </td>
        </tr>
        <!-- Body -->
        <tr>
            <td style="background-color: #ffffff; padding: 40px;">
                <p style="color: #333; font-size: 16px; margin: 0 0 8px;">{greeting}</p>
                <p style="color: #555; font-size: 15px; line-height: 1.6; margin: 0 0 28px;">You requested a login verification code. Enter the code below to complete your sign-in:</p>
                
                <!-- OTP Box -->
                <table role="presentation" width="100%" cellspacing="0" cellpadding="0">
                    <tr>
                        <td style="text-align: center; padding: 24px 0;">
                            <div style="display: inline-block; background: linear-gradient(135deg, #E3F2FD, #BBDEFB); border: 2px solid #1565C0; border-radius: 12px; padding: 20px 48px;">
                                <span style="font-size: 36px; font-weight: 800; letter-spacing: 12px; color: #0D47A1; font-family: 'Courier New', monospace;">{otp}</span>
                            </div>
                        </td>
                    </tr>
                </table>
                
                <!-- Timer -->
                <table role="presentation" width="100%" cellspacing="0" cellpadding="0">
                    <tr>
                        <td style="text-align: center; padding: 8px 0 28px;">
                            <span style="display: inline-block; background-color: #FFF3E0; color: #E65100; font-size: 13px; font-weight: 600; padding: 6px 16px; border-radius: 20px;">⏱ Expires in 5 minutes</span>
                        </td>
                    </tr>
                </table>
                
                <!-- Security Notice -->
                <table role="presentation" width="100%" cellspacing="0" cellpadding="0">
                    <tr>
                        <td style="background-color: #FAFAFA; border-left: 4px solid #F57C00; padding: 16px 20px; border-radius: 0 8px 8px 0;">
                            <p style="color: #666; font-size: 13px; margin: 0; line-height: 1.5;">🔒 <strong>Security Notice:</strong> Never share this code with anyone. Hostelix Pro staff will never ask for your verification code.</p>
                        </td>
                    </tr>
                </table>
            </td>
        </tr>
        <!-- Footer -->
        <tr>
            <td style="background-color: #263238; padding: 24px 40px; border-radius: 0 0 12px 12px; text-align: center;">
                <p style="color: rgba(255,255,255,0.7); font-size: 12px; margin: 0 0 4px;">This is an automated message from Hostelix Pro.</p>
                <p style="color: rgba(255,255,255,0.5); font-size: 11px; margin: 0;">If you didn't request this code, please ignore this email or contact support.</p>
            </td>
        </tr>
    </table>
</body>
</html>
"""
            
            # Attach both plain text and HTML versions
            part1 = MIMEText(text, 'plain')
            part2 = MIMEText(html, 'html')
            message.attach(part1)
            message.attach(part2)
            
            # Send email
            with smtplib.SMTP(smtp_server, smtp_port) as server:
                server.starttls()
                server.login(smtp_username, smtp_password)
                server.sendmail(sender_email, to_email, message.as_string())
            
            return True, None
            
        except Exception as e:
            print(f'Email error: {str(e)}')
            return False, f'Failed to send email: {str(e)}'
    
    @staticmethod
    def send_notification_email(to_email, subject, message_text):
        """
        Send generic notification email
        
        Args:
            to_email: Recipient email
            subject: Email subject
            message_text: Email content
            
        Returns:
            (success: bool, error_message: str)
        """
        try:
            smtp_server = os.getenv('MAIL_SERVER', 'smtp.gmail.com')
            smtp_port = int(os.getenv('MAIL_PORT', 587))
            smtp_username = os.getenv('MAIL_USERNAME')
            smtp_password = os.getenv('MAIL_PASSWORD')
            sender_email = os.getenv('MAIL_DEFAULT_SENDER', 'noreply@hostelixpro.com')
            
            # Skip email in development if not configured
            if not smtp_username or not smtp_password:
                print(f'[DEV MODE] Notification to {to_email}: {subject}')
                return True, None
            
            message = MIMEText(message_text)
            message['Subject'] = subject
            message['From'] = sender_email
            message['To'] = to_email
            
            with smtplib.SMTP(smtp_server, smtp_port) as server:
                server.starttls()
                server.login(smtp_username, smtp_password)
                server.sendmail(sender_email, to_email, message.as_string())
            
            return True, None
            
        except Exception as e:
            print(f'Email error: {str(e)}')
            return False, f'Failed to send email: {str(e)}'

    @staticmethod
    def send_password_reset_email(to_email, otp, display_name=None):
        """
        Send password reset OTP email
        
        Args:
            to_email: Recipient email
            otp: Reset OTP
            display_name: User's name
            
        Returns:
            (success: bool, error_message: str)
        """
        try:
            smtp_server = os.getenv('MAIL_SERVER', 'smtp.gmail.com')
            smtp_port = int(os.getenv('MAIL_PORT', 587))
            smtp_username = os.getenv('MAIL_USERNAME')
            smtp_password = os.getenv('MAIL_PASSWORD')
            sender_email = os.getenv('MAIL_DEFAULT_SENDER', 'noreply@hostelixpro.com')
            
            if not smtp_username or not smtp_password:
                print(f'[DEV MODE] Password Reset OTP for {to_email}: {otp}')
                return True, None
                
            greeting = f'Hello {display_name},' if display_name else 'Hello,'
            
            message = MIMEMultipart('alternative')
            message['Subject'] = 'Hostelix Pro - Password Reset Request'
            message['From'] = sender_email
            message['To'] = to_email
            
            text = f"""
{greeting}

We received a request to reset your password for Hostelix Pro.
Your Password Reset Code is: {otp}

This code will expire in 10 minutes.
Do not share this code with anyone.

If you did not request a password reset, please change your password immediately and contact support.

Best regards,
Hostelix Pro Team
"""
            html = f"""
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
</head>
<body style="margin: 0; padding: 0; background-color: #f0f4f8; font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;">
    <table role="presentation" width="100%" cellspacing="0" cellpadding="0" style="max-width: 600px; margin: 0 auto;">
        <!-- Header -->
        <tr>
            <td style="background: linear-gradient(135deg, #E65100, #F57C00); padding: 32px 40px; text-align: center; border-radius: 12px 12px 0 0;">
                <h1 style="color: #ffffff; margin: 0; font-size: 26px; font-weight: 700; letter-spacing: 0.5px;">Hostelix<span style="color: #FFE0B2;">Pro</span></h1>
                <p style="color: rgba(255,255,255,0.85); margin: 8px 0 0; font-size: 14px; font-weight: 500;">🔑 Password Reset Request</p>
            </td>
        </tr>
        <!-- Body -->
        <tr>
            <td style="background-color: #ffffff; padding: 40px;">
                <p style="color: #333; font-size: 16px; margin: 0 0 8px;">{greeting}</p>
                <p style="color: #555; font-size: 15px; line-height: 1.6; margin: 0 0 28px;">We received a request to reset your Hostelix Pro account password. Use the code below to set a new password:</p>
                
                <!-- OTP Box -->
                <table role="presentation" width="100%" cellspacing="0" cellpadding="0">
                    <tr>
                        <td style="text-align: center; padding: 24px 0;">
                            <div style="display: inline-block; background: linear-gradient(135deg, #FFF3E0, #FFE0B2); border: 2px solid #F57C00; border-radius: 12px; padding: 20px 48px;">
                                <span style="font-size: 36px; font-weight: 800; letter-spacing: 12px; color: #E65100; font-family: 'Courier New', monospace;">{otp}</span>
                            </div>
                        </td>
                    </tr>
                </table>
                
                <!-- Timer -->
                <table role="presentation" width="100%" cellspacing="0" cellpadding="0">
                    <tr>
                        <td style="text-align: center; padding: 8px 0 28px;">
                            <span style="display: inline-block; background-color: #FFEBEE; color: #C62828; font-size: 13px; font-weight: 600; padding: 6px 16px; border-radius: 20px;">⏱ Expires in 10 minutes</span>
                        </td>
                    </tr>
                </table>
                
                <!-- Security Warning -->
                <table role="presentation" width="100%" cellspacing="0" cellpadding="0">
                    <tr>
                        <td style="background-color: #FFF8E1; border-left: 4px solid #F57C00; padding: 16px 20px; border-radius: 0 8px 8px 0;">
                            <p style="color: #666; font-size: 13px; margin: 0 0 6px; line-height: 1.5;">⚠️ <strong>Important:</strong> If you did not request this password reset, your account may be at risk.</p>
                            <p style="color: #888; font-size: 12px; margin: 0; line-height: 1.5;">Please change your password immediately and contact support.</p>
                        </td>
                    </tr>
                </table>
            </td>
        </tr>
        <!-- Footer -->
        <tr>
            <td style="background-color: #263238; padding: 24px 40px; border-radius: 0 0 12px 12px; text-align: center;">
                <p style="color: rgba(255,255,255,0.7); font-size: 12px; margin: 0 0 4px;">This is an automated message from Hostelix Pro.</p>
                <p style="color: rgba(255,255,255,0.5); font-size: 11px; margin: 0;">Never share your reset code. Our staff will never ask for it.</p>
            </td>
        </tr>
    </table>
</body>
</html>
"""
            part1 = MIMEText(text, 'plain')
            part2 = MIMEText(html, 'html')
            message.attach(part1)
            message.attach(part2)
            
            with smtplib.SMTP(smtp_server, smtp_port) as server:
                server.starttls()
                server.login(smtp_username, smtp_password)
                server.sendmail(sender_email, to_email, message.as_string())
                
            return True, None
        except Exception as e:
            print(f'Email error: {str(e)}')
            return False, str(e)
