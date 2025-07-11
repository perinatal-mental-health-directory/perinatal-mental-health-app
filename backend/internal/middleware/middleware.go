package middleware

import (
	"github.com/labstack/echo/v4"
	"github.com/labstack/echo/v4/middleware"
)

// Logger attaches all logging middleware to the Echo instance.
func Logger(e *echo.Echo) {
	e.Use(middleware.Logger())
	e.Use(middleware.Recover())
	e.Use(RequestLogger())
}

// RequestLogger is a custom middleware to log request method and path.
func RequestLogger() echo.MiddlewareFunc {
	return func(next echo.HandlerFunc) echo.HandlerFunc {
		return func(c echo.Context) error {
			method := c.Request().Method
			path := c.Request().URL.Path
			c.Logger().Infof("Incoming request: %s %s", method, path)
			return next(c)
		}
	}
}
