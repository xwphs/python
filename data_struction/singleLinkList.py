class SingleNode:
    """the node of single link list"""
    def __init__(self, item):
        self.item = item
        self.next = None
    def __str__(self):
        return str(self.item)

class SingleLinkList:
    """sing link list"""
    def __init__(self):
        self._head = None

    def is_empty(self):
        """判断链表是否为空"""
        return self._head is None
    
    def length(self):
        """获取链表长度"""
        cur = self._head
        count = 0
        while cur is not None:
            count += 1
            cur = cur.next
        return count
    
    def travel(self):
        """遍历链表"""
        cur = self._head
        while cur is not None:
            print(cur.item)
            cur = cur.next
        print()
    
    def add(self, item):
        """链表头部添加元素"""
        node = SingleNode(item)
        node.next = self._head
        self._head = node

    def append(self, item):
        """链表尾部添加元素"""
        node = SingleNode(item)
        if self.is_empty():
            self._head = node
        else:
            cur = self._head
            while cur.next is not None:
                cur = cur.next

            """此时cur指向最后一个节点，next=None"""
            cur.next = node
        
    def insert(self, pos, item):
        """指定位置添加元素"""
        # 若pos小于0，则执行头部插入
        if pos <= 0:
            self.add(item)
        
        # 若pos大鱼链表长度，则执行尾部插入
        elif pos > self.length() - 1:
            self.append(item)
        
        else:
            node = SingleNode(item)
            cur = self._head
            cur_pos = 0
            while cur.next is not None:
                """获取插入位置的上一个节点"""
                if pos - 1 == cur_pos:
                    node.next = cur.next
                    cur.next = node
                    break
                cur = cur.next
                cur_pos += 1
    
    def remove(self, item):
        """删除节点"""
        cur = self._head
        while cur is not None:
                if cur.next.item == item:
                    cur.next = cur.next.next
                    break
                cur = cur.next
    
    def search(self, item):
        """查找节点位置"""
        cur = self._head
        count = 0
        while cur is not None:
            if cur.item == item:
                return count
            cur = cur.next
            count += 1
        return -1
    
# if __name__ == "__main__":
#     ll = SingleLinkList()
#     ll.add(1)
#     ll.add(2)
#     ll.append(3)
#     ll.insert(2,4)
#     print("length: ", ll.length())
#     ll.travel()
#     print("search(3): ", ll.search(3))
#     print("search(5): ", ll.search(5))
#     ll.remove(1)
#     print("length: ", ll.length())
#     ll.travel()
