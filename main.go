package main

import (
	"fmt"
	"io"
	"bytes"
	"crypto/tls"
	"time"
	"net/url"
	"net/http"
	"log"
	"os"
)

var (
	l2metUrl *url.URL
)

func init() {
	var err error
	u := os.Getenv("L2MET_URL")
	l2metUrl, err = url.Parse(u)
	if err != nil {
		log.Fatal("Unable to parse L2MET_URL.")
	}
	if l2metUrl.Scheme == "https" {
		tr := &http.Transport{TLSClientConfig: &tls.Config{InsecureSkipVerify: true}}
		http.DefaultTransport = tr
	}
}

func main() {
	for _ = range time.Tick(time.Second) {
		go post()
	}
}

func post() {
	var b bytes.Buffer
	prepare(&b, "measure.l2met-canary.http-post")
	req, err := http.NewRequest("POST", l2metUrl.String(), &b)
	resp, err := http.DefaultClient.Do(req)
	b.Reset()
	if err != nil {
		fmt.Fprintf(os.Stderr, "error=%v\n", err)
	} else {
		fmt.Fprintf(os.Stderr, "at=logplex-post status=%v\n", resp.StatusCode)
		resp.Body.Close()
	}
}

func prepare(w io.Writer, msg string) {
	t := time.Now().UTC().Format("2006-01-02T15:04:05+00:00 ")
	lpToken, _ :=  l2metUrl.User.Password()
	msg = "<0>1 " + t + "1234 " + lpToken + " " + "canary[l2met]" + " - - " + msg
	fmt.Fprintf(w, "%d %s", len(msg), msg)
}
