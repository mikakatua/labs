package main

import "fmt"

// Define a struct to represent each row
type Row struct {
	Item string
	Cost float32
	Tax  float32
}

func main() {
	// Create a slice of rows
	table := []Row{
		{"Cake", 0.99, 0.075},
		{"Milk", 2.75, 0.015},
		{"Butter", 0.87, 0.02},
	}
	var totalTax float32
	// Print the sample rows
	for _, row := range table {
		totalTax += row.Cost * row.Tax
	}
	fmt.Printf("Sales Tax Total: %.4f\n", totalTax)
}
