# send smtp e-mail test
import smtplib
from email.mime.text import MIMEText
mail_host = "smtp.qq.com"
mail_user = "1391578633"
mail_pass = "oktnepvzomzdfhje"
sender = "1391578633@qq.com"
receivers = ["1391578633@qq.com", "1497953433@qq.com"]
message = MIMEText("This is a test title", "plain", "utf-8")
message['From'] = sender
message['To'] =";".join(receivers)
message['Subject'] = "This a subject, it's a test"
try:
    smtpObj = smtplib.SMTP(mail_host, 25)
    smtpObj.login(mail_user, mail_pass)
    smtpObj.sendmail(sender, receivers, message.as_string())
    print("send successfully!")
except smtplib.SMTPException as e:
    print(f"senf failed: {e}")
