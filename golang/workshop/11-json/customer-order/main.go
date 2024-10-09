package main

import (
	"encoding/json"
	"fmt"
	"os"
)

type address struct {
	Street  string `json:"street"`
	City    string `json:"city"`
	State   string `json:"state"`
	Zipcode int    `json:"zipcode"`
}

type item struct {
	Name        string  `json:"itemname"`
	Description string  `json:"desc,omitempty"`
	Quantity    int     `json:"qty"`
	Price       float32 `json:"price"`
}

type order struct {
	TotalPrice  float32 `json:"total"`
	IsPaid      bool    `json:"paid"`
	Fragile     bool    `json:",omitempty"`
	OrderDetail []item  `json:"orderdetail"`
}

type customer struct {
	UserName      string  `json:"username"`
	Password      string  `json:"-"`
	Token         string  `json:"-"`
	ShipTo        address `json:"shipto"`
	PurchaseOrder order   `json:"order"`
}

var jsonData = []byte(`
  {
    "username" :"blackhat",
    "shipto":
      {
          "street": "Sulphur Springs Rd",
          "city": "Park City",
          "state": "VA",
          "zipcode": 12345
      },
    "order":
      {
        "paid":false,
        "orderdetail" :
          [{
            "itemname":"A Guide to the World of zeros and ones",
            "desc": "book",
            "qty": 3,
            "price": 50
          }]
      }
  }
`)

func calculatePrice(o order) float32 {
	var sum float32
	for _, i := range o.OrderDetail {
		sum += i.Price * float32(i.Quantity)
	}
	return sum
}

func main() {
	var c customer
	err := json.Unmarshal(jsonData, &c)
	if err != nil {
		fmt.Println("Invalid input json")
		os.Exit(1)
	}
	c.PurchaseOrder.OrderDetail = append(c.PurchaseOrder.OrderDetail, item{Name: "Final Fantasy The Zodiac Age", Description: "Nintendo Switch Game", Quantity: 1, Price: 50})
	c.PurchaseOrder.OrderDetail = append(c.PurchaseOrder.OrderDetail, item{Name: "Crystal Drinking Glass", Quantity: 11, Price: 25})
	c.PurchaseOrder.Fragile = true
	c.PurchaseOrder.TotalPrice = calculatePrice(c.PurchaseOrder)
	data, _ := json.MarshalIndent(c, "", "  ")
	fmt.Println(string(data))
}
