package main

import (
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"os"
)

type NameList struct {
	Names []string
}

func getDataAndParseResponse() map[string]int {
	resp, err := http.Get("http://localhost:8080/names")
	if err != nil {
		fmt.Fprintf(os.Stderr, "error: %v\n", err)
		os.Exit(1)
	}
	defer resp.Body.Close()

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		fmt.Fprintf(os.Stderr, "error: %v\n", err)
		os.Exit(1)
	}

	list := NameList{}
	err = json.Unmarshal(body, &list)
	if err != nil {
		fmt.Fprintf(os.Stderr, "error: %v\n", err)
		os.Exit(1)
	}

	counter := make(map[string]int)
	for _, v := range list.Names {
		counter[v] += 1
	}

	return counter
}

func main() {
	counts := getDataAndParseResponse()

	for k, v := range counts {
		fmt.Printf("%s Count:  %d\n", k, v)
	}
}
