package main

import (
	"bufio"
	"fmt"
	"log"
	"os"
	"strconv"
	"strings"
	"sync"
)

func readFile(fname string, ch chan int, wg *sync.WaitGroup) {
	// Open the file
	file, err := os.Open(fname)
	if err != nil {
		log.Fatalf("failed to open file: %s", err)
	}
	defer file.Close()

	reader := bufio.NewReader(file)
	// Read each line
	for {
		line, err := reader.ReadString('\n')
		if err != nil {
			if err.Error() == "EOF" {
				break
			}
			log.Fatalf("error reading line: %s", err)
		}

		line = strings.TrimSpace(line)

		// Convert the line (string) to an integer
		num, err := strconv.Atoi(line)
		if err != nil {
			log.Fatalf("error converting line to number: %s", err)
		}

		// Send the number to the channel
		ch <- num
	}
	wg.Done()
}

func readNumbers(in chan int, even chan int, odd chan int) {
	for n := range in {
		switch n % 2 {
		case 0:
			even <- n
		case 1:
			odd <- n
		}
	}
	close(even)
	close(odd)
}

func sumNumbers(in chan int, out chan int) {
	sum := 0
	for n := range in {
		sum += n
	}
	out <- sum

}

func writeResult(file string, even chan int, odd chan int, wg *sync.WaitGroup) {

	data := fmt.Sprintf("Even: %d\nOdd : %d\n", <-even, <-odd)

	// Write the data to a file
	err := os.WriteFile(file, []byte(data), 0644)
	if err != nil {
		log.Fatalf("Failed to write to file: %s\n", err)
	}

	fmt.Printf("Result wrote to file %s\n", file)
	wg.Done()
}

func main() {
	ch_num := make(chan int)
	ch_even := make(chan int)
	ch_odd := make(chan int)
	ch_even_sum := make(chan int)
	ch_odd_sum := make(chan int)

	wg1 := &sync.WaitGroup{}
	wg1.Add(2)
	wg2 := &sync.WaitGroup{}
	wg2.Add(1)

	go readFile("file1.txt", ch_num, wg1)
	go readFile("file2.txt", ch_num, wg1)
	go readNumbers(ch_num, ch_even, ch_odd)
	go sumNumbers(ch_even, ch_even_sum)
	go sumNumbers(ch_odd, ch_odd_sum)
	go writeResult("result.txt", ch_even_sum, ch_odd_sum, wg2)

	wg1.Wait()
	close(ch_num)
	wg2.Wait()
	close(ch_even_sum)
	close(ch_odd_sum)
}
