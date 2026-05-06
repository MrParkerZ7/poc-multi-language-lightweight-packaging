package main

import (
	"encoding/json"
	"fmt"
	"time"

	"github.com/google/uuid"
)

func main() {
	payload := map[string]string{
		"hello":     "world",
		"language":  "go",
		"uuid":      uuid.NewString(),
		"timestamp": time.Now().UTC().Format("2006-01-02T15:04:05Z"),
	}
	b, err := json.Marshal(payload)
	if err != nil {
		panic(err)
	}
	fmt.Println(string(b))
}
