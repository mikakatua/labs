package main

import (
	"errors"
	"fmt"
)

var ErrInvalidLastName = errors.New("invalid last name")
var ErrInvalidRoutingNumber = errors.New("invalid routing number")

type directDeposit struct {
	lastName      string
	firstName     string
	bankName      string
	routingNumber int
	accountNumber int
}

func (d directDeposit) validateRoutingNumber() {
	defer func() {
		if r := recover(); r != nil {
			fmt.Println(r)
		}
	}()
	if d.routingNumber < 100 {
		panic(ErrInvalidRoutingNumber)
	}
}

func (d directDeposit) validateLastName() error {
	if d.lastName == "" {
		return ErrInvalidLastName
	}
	return nil
}

func (d directDeposit) report() {
	fmt.Printf("Last Name: %v\n", d.lastName)
	fmt.Printf("First Name: %v\n", d.firstName)
	fmt.Printf("Bank Name: %v\n", d.bankName)
	fmt.Printf("Routing Number: %v\n", d.routingNumber)
	fmt.Printf("Bank Number: %v\n", d.bankName)
}

func main() {
	var err error

	d := directDeposit{"", "Abe", "XYZ Inc", 17, 1809}

	d.validateRoutingNumber()

	err = d.validateLastName()
	if err != nil {
		fmt.Println(err)
	}

	d.report()
}
