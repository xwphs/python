from flask import Flask, request
from flask_cors import CORS
import os
import excel2yml
app = Flask(__name__)
CORS(app)

fname = ''
@app.route("/upload", methods=["POST"])
def save_file():
    data = request.files
    # print("start...")
    # print(data)
    file = data['myFile']
    global fname 
    fname = file.filename
    # print(file.filename)
    # print(request.headers)
    # 文件写入磁盘
    file.save(os.path.join('D:\CloudMusic', fname))
    print("end...")
    return "已接收保存\n"

@app.route("/toyml")
def toyml():
    return excel2yml.transition(f'D:\\CloudMusic\\{fname}')

if __name__ == '__main__':
    app.run()
