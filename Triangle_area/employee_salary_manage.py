from abc import ABC, abstractmethod

class Employee:
    def __init__(self, name) -> None:
        self._name = name
    
    @property
    def name(self):
        return self._name
    
    @name.setter
    def name(self, name):
        self._name = name
    
    @abstractmethod
    def get_salary(self):
        """get salary"""
        pass

class Manager(Employee):
    def __init__(self, name) -> None:
        super().__init__(name)
    
    def get_salary(self):
        return 15000

class Programmer(Employee):
    def __init__(self, name, work_hours=0) -> None:
        super().__init__(name)
        self._work_hours = work_hours
    
    @property
    def work_hours(self):
        return self._work_hours
    
    @work_hours.setter
    def work_hours(self, work_hours):
        self._work_hours = work_hours

    def get_salary(self):
        return 100 * self._work_hours

class Salesman(Employee):
    def __init__(self, name, sales=0) -> None:
        super().__init__(name)
        self._sales = sales
    
    @property
    def sales(self):
        return self._sales
    
    @sales.setter
    def sales(self, sales):
        self._sales = sales
    
    def get_salary(self):
        return 3000 + self._sales * 0.07
    
def main():
    employee_list = [
        Manager('伽罗'), Manager('后羿'), Programmer('艾琳'),
        Programmer('鲁班七号'), Salesman('虞姬'), Salesman('黄忠')
    ]
    for employee in employee_list:
        if isinstance(employee, Programmer):
            employee.work_hours = int(input(f'{employee.name}: Please enter work hours in the month: '))
        elif isinstance(employee, Salesman):
            employee.sales = float(input(f'{employee.name}: Please enter total sales in the month: '))
        else:
            pass
    for emp in employee_list:
        print(f'{emp.name} salary: ￥{emp.get_salary()}')

if __name__ == '__main__':
    main()
