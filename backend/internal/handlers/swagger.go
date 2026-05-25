package handlers

import (
	"net/http"

	"github.com/gin-gonic/gin"
)

func SwaggerHandler() gin.HandlerFunc {
	html := `<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Card API - Swagger UI</title>
    <link rel="stylesheet" type="text/css" href="https://unpkg.com/swagger-ui-dist@5/swagger-ui.css">
    <style>
        html { box-sizing: border-box; overflow: -moz-scrollbars-vertical; overflow-y: scroll; }
        *, *:before, *:after { box-sizing: inherit; }
        body { margin:0; padding:0; }
        .topbar { background-color: #1e3c72; padding: 10px; }
        .topbar .wrapper { display: flex; align-items: center; max-width: 1460px; margin: 0 auto; }
        .topbar .logo { color: white; font-size: 20px; font-weight: bold; text-decoration: none; }
        .topbar .logo span { color: #ffc107; }
    </style>
</head>
<body>
    <div class="topbar">
        <div class="wrapper">
            <a href="#" class="logo"> Card <span>API</span></a>
        </div>
    </div>
    <div id="swagger-ui"></div>
    <script src="https://unpkg.com/swagger-ui-dist@5/swagger-ui-bundle.js"></script>
    <script>
        window.onload = function() {
            const ui = SwaggerUIBundle({
                url: "/api/v1/swagger/doc.json",
                dom_id: '#swagger-ui',
                deepLinking: true,
                presets: [
                    SwaggerUIBundle.presets.apis,
                    SwaggerUIBundle.SwaggerUIStandalonePreset
                ],
                layout: "BaseLayout",
                tryItOutEnabled: true,
                persistAuthorization: true,
                displayRequestDuration: true,
                filter: true,
                defaultModelsExpandDepth: 1,
                defaultModelExpandDepth: 1,
                docExpansion: "list",
                validatorUrl: null
            });
            window.ui = ui;
        };
    </script>
</body>
</html>`

	return func(c *gin.Context) {
		c.Header("Content-Type", "text/html; charset=utf-8")
		c.String(http.StatusOK, html)
	}
}
