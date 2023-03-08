# pip install requests
import requests

url = "https://webfs.ali.kugou.com/202303090042/062a9391930d65e6096df2eee0497d43/KGTX/CLTX001/d0a68d83ccae6cea8335d0e6eea339c2.mp3"
header = {'user-agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/109.0.0.0 Safari/537.36'}
xusong = requests.get(url=url, headers=header)
with open('多余的解释.mp3', 'wb') as f:
    f.write(xusong.content)
