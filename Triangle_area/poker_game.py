import copy
import random

class Card:
    def __init__(self, suite, face) -> None:
        self._suite = suite
        self._face = face
    
    @property
    def suite(self):
        return self._suite
    
    @property
    def face(self):
        return self._face
    
    def __str__(self):
        dic = {1: 'A', 11: 'J', 12: 'Q', 13: 'K'}
        if self._face in dic:
            self._face = dic[self._face]
        else:
            self._face = str(self._face)
        return f'{self._suite}{self._face}'
    
    def __repr__(self):
        return self.__str__()

class Poker:
    def __init__(self) -> None:
        self._cards = [Card(s, f) for s in '♠♥♣♦' for f in range(1, 14)]
        self._current = 0
    
    @property
    def cards(self):
        return self._cards
    
    def shuffle(self):
        random.shuffle(self._cards)
    
    def next(self):
        card = self._cards[self._current]
        self._current += 1
        return card
    
    def have_card(self):
        return self._current < len(self._cards)
      
class Player:
    def __init__(self, name) -> None:
        self._name = name
        self._card_onhand = []
    @property
    def name(self):
        return self._name
    
    @property
    def card_onhand(self):
        return self._card_onhand
    
    def sort(self, key):
        self._card_onhand.sort(key=key)

    def get_card(self, card):
        self._card_onhand.append(card)

def custom_sort(card: Card):
    x = card.face
    if x == 1:
        x += 13
    if x == 2:
        x += 13
    return x

def main():
    poker = Poker()
    poker.shuffle()
    p1 = Player('肖维鹏')
    p2 = Player('杨俊杰')
    p3 = Player('向旭周')

    print(f'Poker List: {copy.deepcopy(poker.cards)}')
    while poker.have_card():
        p1.get_card(poker.next())
        if poker.have_card():
            p2.get_card(poker.next())
        else:
            break
        if poker.have_card():
            p3.get_card(poker.next())
        else:
            break
    p1.sort(key=custom_sort); p2.sort(key=custom_sort); p3.sort(key=custom_sort)
    print(f'{p1.name}: {p1.card_onhand}')
    print(f'{p2.name}: {p2.card_onhand}')
    print(f'{p3.name}: {p3.card_onhand}')

if __name__ == '__main__':
    main()
