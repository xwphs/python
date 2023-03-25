from PySide6.QtWidgets import QApplication, QMainWindow, QPlainTextEdit, QPushButton, QMessageBox

# use a class to collect code
class Stats:
    def __init__(self):
        self.window = QMainWindow()
        self.textEdit = QPlainTextEdit(self.window)
        self.button = QPushButton("Statistics", self.window)
        self.customStyle()
    def customStyle(self):
        self.window.resize(800, 600)
        self.window.setWindowTitle("Salary Statistics")
        self.window.move(200,200)
        self.textEdit.setPlaceholderText("Please type salary")
        self.textEdit.resize(400, 300)
        self.textEdit.move(20, 20)
        self.button.move(700, 550)
        self.button.clicked.connect(self.handleStat)
    def handleStat(self):
        text = self.textEdit.toPlainText()
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
        QMessageBox.about(self.window, 'Statistic Result', f"Salary above 20000:\n{salary_above_2w} \nSalary below 20000:\n{salary_below_2w}")

app = QApplication()
stats = Stats()
stats.window.show()
app.exec()
