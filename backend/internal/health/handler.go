package health

import (
	"net/http"

	"github.com/labstack/echo/v4"
)

// Health handles the /health route
func Health(c echo.Context) error {
	return c.JSON(http.StatusOK, Response{
		Status: "ok",
	})
}
