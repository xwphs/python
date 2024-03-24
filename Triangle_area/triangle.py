import math

class Triangle:
    def __init__(self, a, b, c):
        self._a = a
        self._b = b
        self._c = c
    
    def perimeter(self):
        return self._a + self._b + self._c
    
    def area(self) -> float:
        half = self.perimeter() / 2
        area = math.sqrt(half * (half - self._a) * (half - self._b) * (half - self._c))
        return area
    
    @staticmethod
    def is_valid(a, b, c):
        return a + b > c and a + c > b and b + c > a

def get_input():
    while True:
        sa, sb, sc = input("Please enter the length of the three sides of the triangle: ").split()
        try:
            a = float(sa); b = float(sb); c = float(sc)
        except Exception:
            print('Input error, try again!')
            print()
            # ipute again
        else:
            break
    return a,b,c

def main():
    a, b, c = get_input()
    print(f'Three sides of the triangle: {a}, {b}, {c}')
    if Triangle.is_valid(a, b, c):
        a1 = Triangle(a, b, c)
        print(f'Perimeter: {a1.perimeter()}')
        print(f'Area: {a1.area()}')
    else:
        print("Not a triangle")

if __name__ == '__main__':
    main()
