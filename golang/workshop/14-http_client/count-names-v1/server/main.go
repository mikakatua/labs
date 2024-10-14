package main

import (
	"encoding/json"
	"log"
	"math/rand"
	"net/http"
)

type NameList struct {
	Names []string
}

func generateNames(w http.ResponseWriter, req *http.Request) {
	list := NameList{}
	// Generate random number of 'Electric' names
	for i := 0; i < rand.Intn(5)+1; i++ {
		list.Names = append(list.Names, "Electric")
	}
	// Generate random number of 'Boogaloo' names
	for i := 0; i < rand.Intn(5)+1; i++ {
		list.Names = append(list.Names, "Boogaloo")
	}
	jsonBytes, err := json.Marshal(list)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	log.Println(string(jsonBytes))
	w.Write(jsonBytes)
}

func main() {
	http.HandleFunc("/names", generateNames)
	log.Println("Server is running on :8080")
	log.Fatal(http.ListenAndServe(":8080", nil))
}
