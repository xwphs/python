# send e-main with attachment
import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from email.header import Header

mail_host = "smtp.qq.com"
mail_user = "1391578633"
mail_pass = "oktnepmzdfhje"
sender = "1391578633@qq.com"
receiver = ["1391578633@qq.com", "1497953433@qq.com"]
message = MIMEMultipart()
message['From'] = sender
message['To'] = ";".join(receiver)
message['Subject'] = "This is a test e-mail with attachment"
message.attach(MIMEText('<p>这是正文</p>\
    <h2>giaogiao行行</h2>', "html", "utf-8"))
attach1 = MIMEText(open("test.txt", 'rb').read(), "base64", "utf-8")
attach1['Content-Type'] = "application/octet-stream"
attach1.add_header("Content-Disposition", "attachment", filename=("utf-8","", "他莱莱滴.txt"))
message.attach(attach1)

try:
    smtpObj = smtplib.SMTP()
    smtpObj.connect(mail_host, 25)
    smtpObj.login(mail_user, mail_pass)
    smtpObj.sendmail(sender, receiver, message.as_string())
    print("send successfully!")
except smtplib.SMTPException as e:
    print(f"Send failed! {e}")

