package payroll

import "fmt"

type Employee struct {
	Id        int
	FirstName string
	LastName  string
}

type Payer interface {
	Pay() (string, float64)
}

func PayDetails(p Payer) {
	fullName, pay := p.Pay()
	fmt.Printf("%s got paid %.2f for the year\n", fullName, pay)
}
