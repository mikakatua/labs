package main

import (
	"fmt"
	"strconv"
)

func what(n int) string {
	var msg string
	if n%3 == 0 {
		msg = "Fizz"
	}
	if n%5 == 0 {
		msg += "Buzz"
	}
	if msg == "" {
		msg = strconv.Itoa(n)
	}
	return msg
}

func main() {
	for i := 1; i <= 100; i++ {
		fmt.Println(what(i))
	}
}
