package main

import (
	"flag"
	"fmt"
	"html/template"
	"log"
	"net/http"
	"os"
	"path/filepath"
	"regexp"
)

const PagesDir = "pages"
const TemplatesDir = "templates"
const FrontPageTitle = "FrontPage"

var addr = flag.String("addr", ":8080", "http service address")
var templates = template.Must(template.ParseGlob(filepath.Join(TemplatesDir, "*.html")))

type Page struct {
	Title string
	Body  []byte
}

func (p *Page) save() error {
	filename := filepath.Join(PagesDir, p.Title+".txt")
	err := os.WriteFile(filename, p.Body, 0600)
	if err != nil {
		log.Printf("Page save failed: %q (%s)", p.Title, err.Error())
	}
	return err
}

func load(title string) (*Page, error) {
	filename := filepath.Join(PagesDir, title+".txt")
	body, err := os.ReadFile(filename)
	if err != nil {
		log.Printf("Page load failed: %q (%s)", title, err.Error())
		return nil, err
	}
	return &Page{title, body}, nil
}

func makeHandler(fn func(http.ResponseWriter, *http.Request, string)) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		var validPath = regexp.MustCompile("^/([^/]+)/([a-zA-Z0-9]+)$")

		m := validPath.FindStringSubmatch(r.URL.Path)
		if m == nil {
			log.Printf("Invalid request path: %q", r.URL.Path)
			http.NotFound(w, r)
			return
		}
		fn(w, r, m[2]) // The title is the second subexpression
	}
}

func viewHandler(w http.ResponseWriter, r *http.Request, title string) {
	p, err := load(title)
	if err != nil {
		if os.IsNotExist(err) {
			renderTemplate(w, "create", &Page{Title: title})
			return
		} else {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}
	}
	re := regexp.MustCompile(`\[(.*?)\]`) // backquotes here define a raw string literal (everything between backquotes is taken literally)
	p.Body = []byte(re.ReplaceAllString(string(p.Body), "<a href=\"/view/$1\">$1</a>"))
	renderTemplate(w, "view", p)
}

func editHandler(w http.ResponseWriter, r *http.Request, title string) {
	p, err := load(title)
	if err != nil {
		// Create empty page
		p = &Page{Title: title}
	}
	renderTemplate(w, "edit", p)
}

func saveHandler(w http.ResponseWriter, r *http.Request, title string) {
	body := r.FormValue("body")
	p := &Page{title, []byte(body)}
	err := p.save()
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	// Redirect the client to view the page
	http.Redirect(w, r, "/view/"+title, http.StatusFound)
}

func frontPage(w http.ResponseWriter, r *http.Request) {
	// Redirect the client to the front page
	http.Redirect(w, r, "/view/"+FrontPageTitle, http.StatusFound)
}

func renderTemplate(w http.ResponseWriter, tmpl string, p *Page) {
	// Convert p.Body to template.HTML type so the template engine recognizes it as safe HTML
	// Then we can use .Body directly in the template avoiding printf that is escaping the HTML special characters
	data := struct {
		Title string
		Body  template.HTML
	}{p.Title, template.HTML(p.Body)}
	err := templates.ExecuteTemplate(w, tmpl+".html", data)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
	}
}

func main() {
	flag.Parse()
	http.HandleFunc("/", frontPage)
	http.HandleFunc("/view/", makeHandler(viewHandler))
	http.HandleFunc("/edit/", makeHandler(editHandler))
	http.HandleFunc("/save/", makeHandler(saveHandler))
	log.Println("Starting server at http://localhost" + string(*addr))
	err := http.ListenAndServe(*addr, nil)
	if err != nil {
		log.Fatal("ListenAndServe:", err)
	}

	p1 := &Page{"TestPage", []byte("This is a sample Page.")}
	p1.save()
	p2, _ := load("TestPage")
	fmt.Println(string(p2.Body))

}
