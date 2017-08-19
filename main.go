package main

import (
	"bufio"
	"bytes"
	"flag"
	"fmt"
	"log"
	"os"
	"sort"
	"strings"

	"github.com/kardianos/service"
)

type nameValuePair struct {
	Name  string
	Value string
}
type nameValuePairs []nameValuePair

func (a nameValuePairs) Len() int           { return len(a) }
func (a nameValuePairs) Swap(i, j int)      { a[i], a[j] = a[j], a[i] }
func (a nameValuePairs) Less(i, j int) bool { return a[i].Name < a[j].Name }

type dummyService struct{}

func (d *dummyService) Start(s service.Service) error {
	environment := make([]nameValuePair, 0)
	for _, v := range os.Environ() {
		parts := strings.SplitN(v, "=", 2)
		name := parts[0]
		value := parts[1]
		environment = append(environment, nameValuePair{name, value})
	}
	sort.Sort(nameValuePairs(environment))

	var buffer bytes.Buffer
	w := bufio.NewWriter(&buffer)
	fmt.Fprintln(w, "# Environment Variables")
	for _, v := range environment {
		fmt.Fprintf(w, "%s=%s\n", v.Name, v.Value)
	}
	w.Flush()

	logger, err := s.Logger(nil)
	if err != nil {
		log.Fatal(err)
	}
	logger.Info(buffer.String())
	return nil
}

func (d *dummyService) Stop(s service.Service) error {
	return nil
}

func main() {
	actionFlag := flag.String("action", "", "Action, one of: install, uninstall.")
	nameFlag := flag.String("name", "dummy", "Service name.")
	flag.Parse()
	s, err := service.New(
		&dummyService{},
		&service.Config{
			Name:        *nameFlag,
			Arguments:   []string{"-name", *nameFlag},
			DisplayName: "Dummy Windows Service",
			Description: "Dummy Windows Service",
		})
	if err != nil {
		log.Fatal(err)
	}
	if *actionFlag != "" {
		err := service.Control(s, *actionFlag)
		if err != nil {
			log.Fatal(err)
		}
		return
	}
	logger, err := s.Logger(nil)
	if err != nil {
		log.Fatal(err)
	}
	err = s.Run()
	if err != nil {
		logger.Error(err)
	}
}
