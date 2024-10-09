package main

import (
  "fmt"
)

/*
func bubbleSort(s []int) {
  for l := len(s); l > 1; l-- {
    for i := 0; i < l-1; i++ {
      if s[i] > s[i+1] {
        s[i], s[i+1] = s[i+1], s[i]
      }
    }
  }
}
*/

func bubbleSortLen(s []int, l int) {
  if l > 1 {
    for i := 0; i < l-1; i++ {
      if s[i] > s[i+1] {
        s[i], s[i+1] = s[i+1], s[i]
      }
    }
    bubbleSortLen(s[:l-1], l-1)
  }
}

func bubbleSort(s []int) {
  if l := len(s); l > 1 {
    bubbleSortLen(s, l)
  }
}

func main() {
  numbers := []int{5, 8, 2, 4, 0, 1, 3, 7, 9, 6}

  fmt.Println("Before:", numbers)
  bubbleSort(numbers)
  fmt.Printf("After : %v\n", numbers)
}
