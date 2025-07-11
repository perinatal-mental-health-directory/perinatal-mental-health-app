package main

import (
	"github.com/labstack/echo/v4"
	config "github.com/perinatal-mental-health-app/backend/internal/configs"
	"github.com/perinatal-mental-health-app/backend/internal/middleware"
	"github.com/perinatal-mental-health-app/backend/internal/routes"
	"log"
)

func main() {
	e := echo.New()

	cfg := config.Load()
	db := config.InitPostgres(cfg)

	middleware.Logger(e)

	routes.Register(e, db, cfg)

	log.Fatal(e.Start(":8080"))
}
