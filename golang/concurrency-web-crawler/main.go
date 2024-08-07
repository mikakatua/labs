package main

import (
	"fmt"
	"sync"
	"errors"
)

type Fetcher interface {
	// Fetch returns the body of URL and
	// a slice of URLs found on that page.
	Fetch(url string) (body string, urls []string, err error)
}

// Crawl uses fetcher to recursively crawl
// pages starting with url, to a maximum of depth.
func Crawl(url string, depth int, fetcher Fetcher) {
	// Fetch URLs in parallel.
	// Don't fetch the same URL twice.
	if depth <= 0 {
		return
	}
	body, urls, err := fetcher.Fetch(url)

	cache[url] = struct{
		body string
		err bool
	}{
		body,
		(err != nil),
	}

	var wg sync.WaitGroup

	for _, u := range urls {
		wg.Add(1)
		go func() {
			defer wg.Done()
			Crawl(u, depth-1, fetcher)
		}()
	}
	wg.Wait()
	return
}

var cache = make(map[string]struct{
	body string
	err bool
})

func main() {
	Crawl("https://golang.org/", 4, fetcher)

	for url, res := range cache {
		if res.err {
			fmt.Printf("not found: %s\n", url)
		} else {
			fmt.Printf("found: %s %q\n", url, res.body)
		}
	}
}

// fakeFetcher is Fetcher that returns canned results.
type fakeFetcher map[string]struct{
	body string
	urls []string
}

func (f fakeFetcher) Fetch(url string) (string, []string, error) {
	if res, ok := f[url]; ok {
		return res.body, res.urls, nil
	}
	return "", nil, errors.New("not found")
}

// fetcher is a populated fakeFetcher.
var fetcher = fakeFetcher{
	"https://golang.org/": {
		 "The Go Programming Language",
		[]string{
			"https://golang.org/pkg/",
			"https://golang.org/cmd/",
		},
	},
	"https://golang.org/pkg/": {
		 "Packages",
		[]string{
			"https://golang.org/",
			"https://golang.org/cmd/",
			"https://golang.org/pkg/fmt/",
			"https://golang.org/pkg/os/",
		},
	},
	"https://golang.org/pkg/fmt/": {
		 "Package fmt",
		[]string{
			"https://golang.org/",
			"https://golang.org/pkg/",
		},
	},
	"https://golang.org/pkg/os/": {
		 "Package os",
		[]string{
			"https://golang.org/",
			"https://golang.org/pkg/",
		},
	},
}

