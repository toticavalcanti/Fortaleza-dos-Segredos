package main

import (
	"log"
	"os"

	"github.com/gofiber/fiber/v2"
	"github.com/joho/godotenv"
)

func init() {
	// Load .env file (only for local dev)
	_ = godotenv.Load()
}

func main() {
	// 1) Read secret from env (injected by K8s or .env locally)
	segredo := os.Getenv("SEGREDO")
	if segredo == "" {
		// fallback for dev/local
		segredo = "SEGREDO_NAO_CONFIGURADO"
	}

	// 2) Fiber API
	app := fiber.New()

	// Healthcheck
	app.Get("/health", func(c *fiber.Ctx) error {
		return c.SendStatus(fiber.StatusOK)
	})

	// Secret route
	app.Get("/segredo", func(c *fiber.Ctx) error {
		return c.JSON(fiber.Map{"segredo": segredo})
	})

	log.Println("Servidor iniciado na porta 3000")
	log.Fatal(app.Listen(":3000"))
}