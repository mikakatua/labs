package main

import (
	"fmt"
	"log"
	"net/http"
)

type PageWithCounter struct {
	counter          int
	content, heading string
}

func (p *PageWithCounter) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	p.counter++
	log.Println(r.RequestURI)
	body := fmt.Sprintf("<h1>%s</h1>\n<p>%s<p>\n<p>Views: %d</p>", p.heading, p.content, p.counter)
	w.Write([]byte(body))
}

func main() {
	pages := map[string]*PageWithCounter{
		"/":         {content: "This is the main page", heading: "Hello World"},
		"/chapter1": {content: "This is the first chapter", heading: "Chapter 1"},
		"/chapter2": {content: "This is the second chapter", heading: "Chapter 2"},
	}

	// Handle all incoming requests
	http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		// Find the corresponding page handler based on the request URI
		if page, exists := pages[r.URL.Path]; exists {
			page.ServeHTTP(w, r) // Serve the page
		} else {
			http.NotFound(w, r) // Return 404 if the URI is not found
		}
	})

	log.Fatal(http.ListenAndServe(":8080", nil))
}
