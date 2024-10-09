package payroll

import "fmt"

type Manager struct {
	Individual     Employee
	Salary         float64
	CommissionRate float64
}

func (m Manager) Pay() (string, float64) {
	return fmt.Sprintf("%s %s", m.Individual.FirstName, m.Individual.LastName), m.Salary + (m.Salary * m.CommissionRate)
}
