function uploadFile() {
    var input = document.getElementById("myFile");
    var fileObj = input.files[0];

    var formData = new FormData();
    formData.append("myFile", fileObj)

    var xhr = new XMLHttpRequest();
    xhr.open("POST", "http://127.0.0.1:5000/upload", true);
    xhr.onreadystatechange = function() {
        if (xhr.readyState == 4 && xhr.status == 200) {
            // 上传成功后的处理
            window.alert("Upload Successfully!");
        }
    }
    xhr.send(formData);
}

function transition() {
    console.log(myHttpGet("http://127.0.0.1:5000/toyml"));
}

function myHttpGet(url) {
    var xhr = new XMLHttpRequest();
    xhr.open("GET", url);
    xhr.onreadystatechange = function() {
        if (xhr.readyState == 4 && xhr.status == 200) {
            document.getElementById("contents").innerHTML = xhr.responseText
            return xhr.responseText;
        }
    }
    xhr.send();
    return xhr.responseText;
}
