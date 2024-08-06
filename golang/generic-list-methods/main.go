package main

import "fmt"

// List represents a singly-linked list that holds
// values of any type.
type List[T any] struct {
	next *List[T]
	val  T
}

func (L *List[T]) Append(v T) *List[T] {
	elem := List[T]{nil, v}

	if L == nil {
		return &elem
	}

	current := L
	for {
		if current.next != nil {
			current = current.next
		} else {
			current.next = &elem
			break
		}
	}

	return L
}

func (L *List[T]) Prepend(v T) *List[T] {
	elem := List[T]{L, v}
	return &elem
}

func (L List[T]) String() string {
	s := ""
	current := &L

	for {
		s = s + fmt.Sprintf("%v; ", current.val)
		if current.next != nil {
			current = current.next
		} else {
			break
		}
	}

	return s
}

func main() {
	var numList *List[int]
	numList = numList.Append(22)
	numList.Append(33)
	numList = numList.Prepend(11)
	fmt.Println(numList)

	strList := &List[string]{nil, "hola"}
	strList.Append("mundo")
	strList = strList.Prepend("primero")
	fmt.Println(strList)

}

