package main

import "fmt"

func getType(v interface{}) string {
	switch v.(type) {
	case int, int32, int64:
		return "int"
	case float32, float64:
		return "float"
	case string, bool:
		return fmt.Sprintf("%T", v)
	default:
		return "unknown"
	}

}

func main() {
	data := []interface{}{1, 3.14, "hello", true, struct{}{}}
	for _, val := range data {
		fmt.Printf("%v is %v\n", val, getType(val))
	}
}
