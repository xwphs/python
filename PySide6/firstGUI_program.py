# pip install pyside6
from PySide6.QtWidgets import QApplication, QMainWindow, QPlainTextEdit, QPushButton, QMessageBox

# a slot that handle the button clicked singal.
def handleStat():
    text = textEdit.toPlainText()
    salary_above_2w = ''
    salary_below_2w = ''
    for line in text.splitlines():
        if not line.strip():
            continue
        parts = line.split()
        name, salary, age = parts
        if int(salary) >= 20000:
            salary_above_2w += name + "\n"
        else:
            salary_below_2w += name + "\n"
    QMessageBox.about(window, 'Statistic Result', f"Salary above 20000:\n{salary_above_2w} \nSalary below 20000:\n{salary_below_2w}")

app = QApplication()    # create application
window = QMainWindow()  # create main window
window.resize(800, 600)
window.setWindowTitle("Salary Statistics")
window.move(200,200)
textEdit = QPlainTextEdit(window)   # create plaintext editor
textEdit.setPlaceholderText("Please type salary")
textEdit.resize(400, 300)
textEdit.move(20, 20)
button = QPushButton("Statistics", window)    # create button
button.move(700, 550)
button.clicked.connect(handleStat)
window.show()
app.exec()
