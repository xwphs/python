from PySide6.QtWidgets import QApplication, QMainWindow, QMessageBox
from abcd import Ui_form

class Stats(QMainWindow):
    def __init__(self):
        super(Stats, self).__init__()
        self.ui = Ui_form()
        self.ui.setupUi(self)
        self.ui.pushButton.clicked.connect(self.handleStat)
    def handleStat(self):
        text = self.ui.plainTextEdit.toPlainText()
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
        QMessageBox.about(self, 'Statistic Result', f"Salary above 20000:\n{salary_above_2w} \nSalary below 20000:\n{salary_below_2w}")
app = QApplication()
stats = Stats()
stats.show()
app.exec()

# This time I use pyside6-uic.exe file to convert a ui_file to a python_file (abcd.py)
# then import it to the current code(from abcd import Ui_form)
# define a class that inherits QMainWindow and init it(super(Stats, self).__init__(); self.ui = Ui_form(); self.ui.setupUi(self))
