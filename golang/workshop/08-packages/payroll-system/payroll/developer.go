package payroll

import (
	"errors"
	"fmt"
)

type Developer struct {
	Individual        Employee
	HourlyRate        float64
	HoursWorkedInYear float64
	Review            map[string]interface{}
}

func (d Developer) Pay() (string, float64) {
	return fmt.Sprintf("%s %s", d.Individual.FirstName, d.Individual.LastName), d.HourlyRate * d.HoursWorkedInYear
}

func getReview(i interface{}) (float64, error) {
	switch v := i.(type) {
	case int:
		if v > 0 && v < 6 {
			return float64(v), nil
		} else {
			return 0.0, fmt.Errorf("invalid rating: %v", v)
		}
	case string:
		switch v {
		case "Excellent":
			return 5.0, nil
		case "Good":
			return 4.0, nil
		case "Fair":
			return 3.0, nil
		case "Poor":
			return 2.0, nil
		case "Unsatisfactory":
			return 1.0, nil
		default:
			return 0.0, errors.New("invalid rating: " + v)
		}
	default:
		return 0.0, errors.New("unknown type")
	}
}

func (d *Developer) ReviewRating() error {
	count, sum := 0.0, 0.0
	for _, v := range d.Review {
		review, err := getReview(v)
		if err != nil {
			return err
		}
		sum += review
		count++
	}
	fmt.Printf("%s %s got a review rating of %.2f\n", d.Individual.FirstName, d.Individual.LastName, sum/count)
	return nil
}
