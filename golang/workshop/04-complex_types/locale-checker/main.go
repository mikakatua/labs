package main

import (
	"fmt"
	"os"
	"strings"
)

type locale struct {
	language  string
	territory string
}

var supportedLocales = map[locale]bool{
	{"en", "US"}: true,
	{"en", "CN"}: true,
	{"fr", "CN"}: true,
	{"fr", "FR"}: true,
	{"ru", "RU"}: true,
}

func isSupported(loc locale) bool {
	_, exists := supportedLocales[loc]
	return exists
}

func main() {
	if len(os.Args) != 2 {
		fmt.Println("Invalid input")
		os.Exit(1)
	}
	localeParts := strings.Split(os.Args[1], "_")
	if len(localeParts) != 2 {
		fmt.Println("Invalid locale")
		os.Exit(1)
	}

	myLocale := locale{localeParts[0], localeParts[1]}

	if isSupported(myLocale) {
		fmt.Println("Locale supported")
	} else {
		fmt.Println("Locale not supported")
	}
}
