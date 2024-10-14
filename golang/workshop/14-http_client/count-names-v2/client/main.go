package main

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"log"
	"math/rand"
	"net/http"
	"os"
)

type NameList struct {
	Names []string
}

func generateNames() NameList {
	list := NameList{}
	// Generate random number of 'Electric' names
	for i := 0; i < rand.Intn(5)+1; i++ {
		list.Names = append(list.Names, "Electric")
	}
	// Generate random number of 'Boogaloo' names
	for i := 0; i < rand.Intn(5)+1; i++ {
		list.Names = append(list.Names, "Boogaloo")
	}
	return list
}

func postDataAndCheckStatus(list NameList) error {
	jsonBytes, err := json.Marshal(list)
	if err != nil {
		return err
	}

	resp, err := http.Post("http://localhost:8080/names", "application/json", bytes.NewBuffer(jsonBytes))
	if err != nil {
		return err
	}
	resp.Body.Close()

	return nil
}

func getDataAndParseResponse() map[string]int {
	resp, err := http.Get("http://localhost:8080/names")
	if err != nil {
		log.Fatal(err)
	}
	defer resp.Body.Close()

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		log.Fatal(err)
	}

	list := NameList{}
	err = json.Unmarshal(body, &list)
	if err != nil {
		log.Fatal(err)
	}

	counter := make(map[string]int)
	for _, v := range list.Names {
		counter[v] += 1
	}

	return counter
}

func main() {
	list := generateNames()
	fmt.Println(list)

	if err := postDataAndCheckStatus(list); err != nil {
		fmt.Fprintf(os.Stderr, "error: %v\n", err)
		os.Exit(1)
	}
	counts := getDataAndParseResponse()

	for k, v := range counts {
		fmt.Printf("%s Count:  %d\n", k, v)
	}
}
