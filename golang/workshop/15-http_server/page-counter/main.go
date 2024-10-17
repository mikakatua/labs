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
	main := PageWithCounter{content: "This is the main page", heading: "Hello World"}
	chapter1 := PageWithCounter{content: "This is the first chapter", heading: "Chapter 1"}
	chapter2 := PageWithCounter{content: "This is the second chapter", heading: "Chapter 2"}

	http.Handle("/", &main)
	http.Handle("/chapter1", &chapter1)
	http.Handle("/chapter2", &chapter2)
	log.Fatal(http.ListenAndServe(":8080", nil))
}
