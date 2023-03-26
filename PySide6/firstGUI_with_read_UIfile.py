from PySide6.QtWidgets import QApplication, QMessageBox
from PySide6.QtUiTools import QUiLoader
from PySide6.QtCore import QFile
class Stats:
    def __init__(self):
        ui_file = QFile('ui/statistics.ui')
        ui_file.open(QFile.ReadOnly)
        self.form = QUiLoader().load(ui_file)
        ui_file.close()
        self.form.pushButton.clicked.connect(self.handleStat)
    def handleStat(self):
        text = self.form.plainTextEdit.toPlainText()
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
        QMessageBox.about(self.form, 'Statistic Result', f"Salary above 20000:\n{salary_above_2w} \nSalary below 20000:\n{salary_below_2w}")
app = QApplication()
stats = Stats()
stats.form.show()
app.exec()

# I use designer.exe to generate a UI file(ui/statistics.ui), then read it in the code to create form.
# step by step details:
# ui_file = QFile('ui/statistics.ui'); ui_file.open(QFile.ReadOnly); self.form = QUiLoader().load(ui_file); ui_file.close()
