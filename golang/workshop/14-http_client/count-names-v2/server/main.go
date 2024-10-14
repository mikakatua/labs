package main

import (
	"encoding/json"
	"log"
	"net/http"
)

var names []string

type NameList struct {
	Names []string `json:"names"`
}

func addNames(w http.ResponseWriter, req *http.Request) {
	list := NameList{}
	if err := json.NewDecoder(req.Body).Decode(&list); err != nil {
		http.Error(w, "Bad request: "+err.Error(), http.StatusBadRequest)
		return
	}
	defer req.Body.Close()

	if list.Names == nil {
		http.Error(w, "Invalid JSON", http.StatusBadRequest)
		return
	}

	for _, v := range list.Names {
		names = append(names, v)
		log.Println("Added:", v)
	}

	w.WriteHeader(http.StatusOK)
}

func getNames(w http.ResponseWriter, req *http.Request) {
	list := NameList{Names: names}
	jsonBytes, err := json.Marshal(list)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	log.Println(string(jsonBytes))
	w.Write(jsonBytes)
}

func main() {
	http.HandleFunc("GET /names", getNames)
	http.HandleFunc("POST /names", addNames)
	log.Println("Server is running on :8080")
	log.Fatal(http.ListenAndServe(":8080", nil))
}
