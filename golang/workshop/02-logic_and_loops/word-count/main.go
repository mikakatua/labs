package main

import (
	"fmt"
)

var words = map[string]int{
	"Gonna": 3,
	"You":   3,
	"Give":  2,
	"Never": 1,
	"Up":    4,
}

func main() {
	kmax, vmax := "", 0
	for k, v := range words {
		if v > vmax {
			kmax, vmax = k, v
		}
	}
	fmt.Println("Most popular word:", kmax)
	fmt.Println("With a count of  :", vmax)
}
