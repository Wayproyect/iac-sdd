package main

import (
	"fmt"
	"log"
	"net/http"
	"os"
)

func handler(w http.ResponseWriter, r *http.Request) {
	podID := os.Getenv("HOSTNAME")
	if podID == "" {
		podID = "unknown-pod"
	}
	fmt.Fprintf(w, "Hello from k3s %s\n", podID)
}

func main() {
	http.HandleFunc("/", handler)
	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	log.Printf("Server listening on port %s", port)
	log.Fatal(http.ListenAndServe(":"+port, nil))
}
