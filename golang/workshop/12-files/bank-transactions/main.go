package main

import (
	"encoding/csv"
	"errors"
	"flag"
	"fmt"
	"io"
	"log"
	"os"
	"strconv"
	"strings"
	"text/tabwriter"
)

var (
	ErrBudgetCategoryNotFound = errors.New("The budget category does not exists.")
)

type budgetCategory int

const (
	autoFuel budgetCategory = iota
	food
	mortgage
	repairs
	insurance
	utilities
)

func convertToBudgeCategory(category string) (budgetCategory, error) {
	switch category {
	case "fuel", "gas":
		return autoFuel, nil
	case "food":
		return food, nil
	case "mortgage":
		return mortgage, nil
	case "repairs":
		return repairs, nil
	case "car insurance", "life insurance":
		return insurance, nil
	case "utilities":
		return utilities, nil
	default:
		return -1, ErrBudgetCategoryNotFound
	}
}

type transaction struct {
	id       int
	payee    string
	spent    float32
	category budgetCategory
}

func parseBankFile(bankTransactions io.Reader, logger *log.Logger) []transaction {
	tx := []transaction{}
	r := csv.NewReader(bankTransactions)
	header := true
	for {
		record, err := r.Read()
		if err == io.EOF {
			break
		}
		if err != nil {
			logger.Println("Error in record.", err, record)
			continue
		}
		if !header {
			skip := false
			t := transaction{}
		main_loop:
			for idx, val := range record {
				switch idx {
				case 0:
					n, err := strconv.Atoi(val)
					if err != nil {
						logger.Println("Error in field 'id'.", err, record)
						skip = true
						break main_loop
					}
					t.id = n
				case 1:
					t.payee = strings.TrimSpace(val)
				case 2:
					f, err := strconv.ParseFloat(strings.TrimSpace(val), 32)
					if err != nil {
						logger.Println("Error in field 'spent'.", err, record)
						skip = true
						break main_loop
					}
					t.spent = float32(f)
				case 3:
					c, err := convertToBudgeCategory(strings.TrimSpace(val))
					if err != nil {
						logger.Println("Error in field 'category'.", err, record)
						skip = true
						break main_loop
					}
					t.category = c
				}
			}
			if !skip {
				tx = append(tx, t)
			}
		}
		header = false
	}
	return tx
}

func main() {
	csvFile := flag.String("c", "transactions.csv", "Input CSV file (default transactions.csv)")
	logFile := flag.String("l", "transactions.log", "Output Log file (default transactions.log)")
	flag.Parse()

	csvf, err := os.OpenFile(*csvFile, os.O_RDONLY, 0400)
	if err != nil {
		fmt.Println(err)
		os.Exit(1)
	}
	defer csvf.Close()

	logf, err := os.OpenFile(*logFile, os.O_WRONLY|os.O_CREATE|os.O_TRUNC, 0600)
	if err != nil {
		fmt.Println(err)
		os.Exit(1)
	}
	defer logf.Close()

	logger := log.New(logf, "", log.Ldate|log.Ltime)

	transactions := parseBankFile(csvf, logger)
	w := tabwriter.NewWriter(os.Stdout, 0, 1, 2, ' ', 0)
	fmt.Fprintln(w, "ID\tPAYEE\tSPENT\tCAT")
	for _, t := range transactions {
		fmt.Fprintf(w, "%v\t%v\t%v\t%v\n", t.id, t.payee, t.spent, t.category)
	}
	w.Flush()
}
