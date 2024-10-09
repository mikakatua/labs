package main

import (
	"fmt"
	"os"
)

var m = map[string]string{
	"305": "Sue",
	"204": "Bob",
	"631": "Jake",
	"073": "Tracy",
}

func main() {
	if len(os.Args) != 2 {
		fmt.Println("Only one argument expected")
		os.Exit(1)
	}

	user, ok := m[os.Args[1]]

	if ok {
		fmt.Println("Hi,", user)
	} else {
		fmt.Println("Not found")
	}
}
