package server

import (
	"fmt"
	"net/http"
	"os"
	"strconv"
	"time"

	_ "github.com/joho/godotenv/autoload"

	"kilimo/internal/database"
	"kilimo/internal/ml"
	"kilimo/internal/nasa"
	"kilimo/internal/rotation"
	"kilimo/internal/soil"
)

type Server struct {
	port int

	db       database.Service
	nasa     *nasa.Service
	soil     *soil.Service
	ml       *ml.Engine
	rotation *rotation.Service
}

func NewServer() *http.Server {
	portStr := os.Getenv("PORT")
	port, _ := strconv.Atoi(portStr)
	if port == 0 {
		port = 8080
	}

	climateCsv := "training_data/kenya-climate-data-1991-2016-rainfallmm.csv"
	soilCsv := "training_data/kenya_regional_soil_data.csv"

	nasaSvc := nasa.NewService(climateCsv)
	soilSvc, _ := soil.NewService(soilCsv)
	mlEngine := ml.NewEngine()
	rotationSvc := rotation.NewService(nasaSvc, soilSvc, mlEngine)

	s := &Server{
		port:     port,
		db:       database.New(),
		nasa:     nasaSvc,
		soil:     soilSvc,
		ml:       mlEngine,
		rotation: rotationSvc,
	}

	// Declare Server config
	httpServer := &http.Server{
		Addr:         fmt.Sprintf(":%d", s.port),
		Handler:      s.RegisterRoutes(),
		IdleTimeout:  time.Minute,
		ReadTimeout:  15 * time.Second,
		WriteTimeout: 45 * time.Second,
	}

	return httpServer
}
