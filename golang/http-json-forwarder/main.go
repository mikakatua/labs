package main

import (
	"bytes"
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"os"
)

/*
Sample incoming request (from AWX)

{
   "id":46,
   "name":"AWX-Collection-tests-awx_job_wait-long_running-XVFBGRSAvUUIrYKn",
   "url":"https://host/#/jobs/playbook/46",
   "created_by":"bianca",
   "started":"2020-07-28T20:43:36.966686+00:00",
   "finished":"2020-07-28T20:43:44.936072+00:00",
   "status":"failed",
   "traceback":"",
   "inventory":"Demo Inventory",
   "project":"AWX-Collection-tests-awx_job_wait-long_running-JJSlglnwtsRJyQmw",
   "playbook":"fail.yml",
   "credential":null,
   "limit":"",
   "extra_vars":"{\"sleep_interval\": 300}",
   "hosts":{
      "localhost":{
         "failed":true,
         "changed":0,
         "dark":0,
         "failures":1,
         "ok":1,
         "processed":1,
         "skipped":0,
         "rescued":0,
         "ignored":0
      }
   }
}

Transformed outgoing request (to Rocket Chat)

{
  "status": "failed",
  "externalURL": "https://host/#/jobs/playbook/46",
  "alerts": [
    {
      "labels": {
        "alertname": "AWX Job failed"
      },
      "annotations": {
        "message": "Job 46: AWX-Collection-tests-awx_job_wait-long_running-XVFBGRSAvUUIrYKn"
      }
    }
  ]
}
*/

var rocketURL = os.Getenv("ROCKET_URL")

func validateRequest(input map[string]interface{}) bool {
	// Validate input fields
	inputOk := true
	for _, key := range []string{"id", "name", "url", "status"} {
		val, ok := input[key]
		if key == "status" && val == "failed" || key != "status" && ok {
			continue
		}
		inputOk = false
	}

	return inputOk
}

func webhookHandler(w http.ResponseWriter, r *http.Request) {
	var request map[string]interface{}

	// Decode the incoming JSON request
	if err := json.NewDecoder(r.Body).Decode(&request); err != nil {
		http.Error(w, "Bad request: "+err.Error(), http.StatusBadRequest)
		return
	}
	defer r.Body.Close()

	// Validate incoming JSON request
	if !validateRequest(request) {
		http.Error(w, "Bad request: Invalid JSON", http.StatusBadRequest)
		return
	}

	// Prepare outgoing request
	payload := fmt.Sprintf(`{
    "status": "%v",
    "externalURL": "%v",
    "alerts": [
      {
        "labels": {
          "alertname": "AWX Job failed"
        },
        "annotations": {
          "message": "Job %v: %v"
        }
      }
    ]
  }`, request["status"], request["url"], request["id"], request["name"])

	// Send the transformed payload to the external URL
	resp, err := http.Post(rocketURL, "application/json", bytes.NewBuffer([]byte(payload)))
	if err != nil {
		http.Error(w, "Failed to send request: "+err.Error(), http.StatusInternalServerError)
		return
	}
	defer resp.Body.Close()

	// Send HTTP Status OK
	w.WriteHeader(http.StatusOK)
	fmt.Fprintln(w, "Webhook processed successfully")
}

func init() {
	if rocketURL == "" {
		panic("missing env variable ROCKET_URL")
	}
}

func main() {
	http.HandleFunc("/webhook", webhookHandler)

	// Start the server on port 8080.
	fmt.Println("Server starting on port 8080...")
	if err := http.ListenAndServe(":8080", nil); err != nil {
		log.Fatalf("Failed to start server: %v", err)
	}
}
