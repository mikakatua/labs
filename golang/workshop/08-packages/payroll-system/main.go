package main

import (
  pr "payroll-system/payroll"
	"fmt"
	"os"
)

var employeeReview = make(map[string]interface{})

func init() {
	employeeReview["WorkQuality"] = 5
	employeeReview["TeamWork"] = 2
	employeeReview["Communication"] = "Poor"
	employeeReview["Problem-solving"] = 4
	employeeReview["Dependability"] = "Unsatisfactory"
}

func main() {
	developer := pr.Developer{Individual: pr.Employee{Id: 1, FirstName: "Eric", LastName: "Davis"}, HourlyRate: 35, HoursWorkedInYear: 2400, Review: employeeReview}
	manager := pr.Manager{Individual: pr.Employee{Id: 2, FirstName: "Mr.", LastName: "Boss"}, Salary: 150000, CommissionRate: .07}
	err := developer.ReviewRating()
	if err != nil {
		fmt.Println(err)
		os.Exit(1)
	}
	pr.PayDetails(developer)
	pr.PayDetails(manager)
}
