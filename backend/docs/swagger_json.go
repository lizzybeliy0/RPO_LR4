package docs

var SwaggerJSON = `{
  "swagger": "2.0",
  "info": {
    "title": "Card Payment Authorization API",
    "description": "REST API for card payment authorization system",
    "version": "1.0"
  },
  "host": "localhost:8888",
  "basePath": "/api/v1",
  "paths": {
    "/auth/login": {
      "post": {
        "tags": ["auth"],
        "summary": "User login",
        "description": "Authenticate user and get JWT token",
        "consumes": ["application/json"],
        "produces": ["application/json"],
        "parameters": [{
          "in": "body",
          "name": "body",
          "required": true,
          "schema": {
            "type": "object",
            "required": ["login", "password"],
            "properties": {
              "login": {"type": "string", "example": "admin"},
              "password": {"type": "string", "example": "password"}
            }
          }
        }],
        "responses": {
          "200": {
            "description": "OK",
            "schema": {
              "type": "object",
              "properties": {
                "token": {"type": "string", "example": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."}
              }
            }
          },
          "400": {"description": "Invalid credentials"}
        }
      }
    },
    "/auth/me": {
      "get": {
        "tags": ["auth"],
        "summary": "Get current user",
        "security": [{"BearerAuth": []}],
        "responses": {
          "200": {"description": "OK", "schema": {"$ref": "#/definitions/User"}},
          "401": {"description": "Unauthorized"}
        }
      }
    },
    "/users": {
      "get": {
        "tags": ["users"],
        "summary": "List all users",
        "security": [{"BearerAuth": []}],
        "responses": {
          "200": {"description": "OK", "schema": {"type": "array", "items": {"$ref": "#/definitions/User"}}},
          "401": {"description": "Unauthorized"}
        }
      },
      "post": {
        "tags": ["users"],
        "summary": "Create a new user",
        "description": "Creates a new user (admin only)",
        "security": [{"BearerAuth": []}],
        "consumes": ["application/json"],
        "produces": ["application/json"],
        "parameters": [{
          "in": "body",
          "name": "body",
          "required": true,
          "schema": {
            "type": "object",
            "required": ["login", "password"],
            "properties": {
              "login": {"type": "string", "example": "john_doe", "minLength": 3, "maxLength": 100},
              "password": {"type": "string", "example": "password123", "minLength": 6},
              "is_admin": {"type": "boolean", "example": false, "default": false},
              "card_id": {"type": "integer", "example": 1, "description": "Card ID to assign to user (optional)"}
            }
          }
        }],
        "responses": {
          "201": {"description": "Created", "schema": {"$ref": "#/definitions/User"}},
          "400": {"description": "Invalid input"},
          "401": {"description": "Unauthorized"},
          "403": {"description": "Forbidden - admin only"}
        }
      }
    },
    "/users/{id}": {
      "get": {
        "tags": ["users"],
        "summary": "Get user by ID",
        "security": [{"BearerAuth": []}],
        "parameters": [{"in": "path", "name": "id", "required": true, "type": "integer", "description": "User ID"}],
        "responses": {
          "200": {"description": "OK", "schema": {"$ref": "#/definitions/User"}},
          "401": {"description": "Unauthorized"},
          "404": {"description": "User not found"}
        }
      },
      "put": {
        "tags": ["users"],
        "summary": "Update a user",
        "description": "Updates user data (admin only or own user)",
        "security": [{"BearerAuth": []}],
        "consumes": ["application/json"],
        "produces": ["application/json"],
        "parameters": [
          {"in": "path", "name": "id", "required": true, "type": "integer", "description": "User ID"},
          {
            "in": "body",
            "name": "body",
            "required": true,
            "schema": {
				"type": "object",
              "properties": {
                "login": {"type": "string", "example": "new_login"},
                "password": {"type": "string", "example": "new_password"},
                "is_admin": {"type": "boolean", "example": false},
                "card_id": {"type": "integer", "example": 1, "description": "Card ID to assign to user (can be null)"}
              }
            }
          }
        ],
        "responses": {
          "200": {"description": "OK", "schema": {"$ref": "#/definitions/User"}},
          "400": {"description": "Invalid input"},
          "401": {"description": "Unauthorized"},
          "403": {"description": "Forbidden"},
          "404": {"description": "User not found"}
        }
      },
      "delete": {
        "tags": ["users"],
        "summary": "Delete a user",
        "description": "Deletes a user (admin only)",
        "security": [{"BearerAuth": []}],
        "parameters": [{"in": "path", "name": "id", "required": true, "type": "integer", "description": "User ID"}],
        "responses": {
          "204": {"description": "No Content"},
          "401": {"description": "Unauthorized"},
          "403": {"description": "Forbidden - admin only"},
          "404": {"description": "User not found"}
        }
      }
    },
    "/cards": {
      "get": {
        "tags": ["cards"],
        "summary": "List all cards",
        "security": [{"BearerAuth": []}],
        "responses": {
          "200": {"description": "OK", "schema": {"type": "array", "items": {"$ref": "#/definitions/Card"}}},
          "401": {"description": "Unauthorized"}
        }
      },
      "post": {
        "tags": ["cards"],
        "summary": "Create a new card",
        "description": "Creates a new transport card (admin only)",
        "security": [{"BearerAuth": []}],
        "consumes": ["application/json"],
        "produces": ["application/json"],
        "parameters": [{
          "in": "body",
          "name": "body",
          "required": true,
          "schema": {
            "type": "object",
            "required": ["number", "owner_name", "key_id"],
            "properties": {
              "number": {"type": "string", "example": "1234567890", "minLength": 10, "maxLength": 20},
              "balance": {"type": "integer", "example": 1000, "minimum": 0, "default": 0},
              "blocked": {"type": "boolean", "example": false, "default": false},
              "owner_name": {"type": "string", "example": "Ivan Ivanov", "maxLength": 255},
              "key_id": {"type": "integer", "example": 1, "minimum": 1}
            }
          }
        }],
        "responses": {
          "201": {"description": "Created", "schema": {"$ref": "#/definitions/Card"}},
          "400": {"description": "Invalid input"},
          "401": {"description": "Unauthorized"},
          "403": {"description": "Forbidden - admin only"}
        }
      }
    },
    "/cards/{id}": {
      "get": {
        "tags": ["cards"],
        "summary": "Get a card by ID",
        "security": [{"BearerAuth": []}],
        "parameters": [{"in": "path", "name": "id", "required": true, "type": "integer", "description": "Card ID"}],
        "responses": {
          "200": {"description": "OK", "schema": {"$ref": "#/definitions/Card"}},
          "401": {"description": "Unauthorized"},
          "404": {"description": "Card not found"}
        }
      },
      "put": {
        "tags": ["cards"],
        "summary": "Update a card",
        "description": "Updates card data (admin only)",
        "security": [{"BearerAuth": []}],
        "consumes": ["application/json"],
        "produces": ["application/json"],
        "parameters": [
          {"in": "path", "name": "id", "required": true, "type": "integer", "description": "Card ID"},
          {
            "in": "body",
            "name": "body",
            "required": true,
            "schema": {
              "type": "object",
              "properties": {
                "number": {"type": "string", "example": "1234567890"},
                "balance": {"type": "integer", "example": 1500, "minimum": 0},
                "blocked": {"type": "boolean", "example": false},
"owner_name": {"type": "string", "example": "Ivan Ivanov"},
                "key_id": {"type": "integer", "example": 1}
              }
            }
          }
        ],
        "responses": {
          "200": {"description": "OK", "schema": {"$ref": "#/definitions/Card"}},
          "400": {"description": "Invalid input"},
          "401": {"description": "Unauthorized"},
          "403": {"description": "Forbidden - admin only"},
          "404": {"description": "Card not found"}
        }
      },
      "delete": {
        "tags": ["cards"],
        "summary": "Delete a card",
        "description": "Deletes a card (admin only)",
        "security": [{"BearerAuth": []}],
        "parameters": [{"in": "path", "name": "id", "required": true, "type": "integer", "description": "Card ID"}],
        "responses": {
          "204": {"description": "No Content"},
          "401": {"description": "Unauthorized"},
          "403": {"description": "Forbidden - admin only"},
          "404": {"description": "Card not found"}
        }
      }
    },
    "/terminals": {
      "get": {
        "tags": ["terminals"],
        "summary": "List all terminals",
        "security": [{"BearerAuth": []}],
        "responses": {
          "200": {"description": "OK", "schema": {"type": "array", "items": {"$ref": "#/definitions/Terminal"}}},
          "401": {"description": "Unauthorized"}
        }
      },
      "post": {
        "tags": ["terminals"],
        "summary": "Create a new terminal",
        "description": "Creates a new terminal (admin only)",
        "security": [{"BearerAuth": []}],
        "consumes": ["application/json"],
        "produces": ["application/json"],
        "parameters": [{
          "in": "body",
          "name": "body",
          "required": true,
          "schema": {
            "type": "object",
            "required": ["serial", "address", "name"],
            "properties": {
              "serial": {"type": "string", "example": "TERM-001", "minLength": 3},
              "address": {"type": "string", "example": "Metro Station 1"},
              "name": {"type": "string", "example": "Metro Terminal 1"}
            }
          }
        }],
        "responses": {
          "201": {"description": "Created", "schema": {"$ref": "#/definitions/Terminal"}},
          "400": {"description": "Invalid input"},
          "401": {"description": "Unauthorized"},
          "403": {"description": "Forbidden - admin only"}
        }
      }
    },
    "/terminals/{id}": {
      "get": {
        "tags": ["terminals"],
        "summary": "Get a terminal by ID",
        "security": [{"BearerAuth": []}],
        "parameters": [{"in": "path", "name": "id", "required": true, "type": "integer", "description": "Terminal ID"}],
        "responses": {
          "200": {"description": "OK", "schema": {"$ref": "#/definitions/Terminal"}},
          "401": {"description": "Unauthorized"},
          "404": {"description": "Terminal not found"}
        }
      },
      "put": {
        "tags": ["terminals"],
        "summary": "Update a terminal",
        "description": "Updates terminal data (admin only)",
        "security": [{"BearerAuth": []}],
        "consumes": ["application/json"],
        "produces": ["application/json"],
        "parameters": [
          {"in": "path", "name": "id", "required": true, "type": "integer", "description": "Terminal ID"},
          {
            "in": "body",
            "name": "body",
            "required": true,
            "schema": {
              "type": "object",
              "properties": {
                "serial": {"type": "string", "example": "TERM-001-UPDATED"},
                "address": {"type": "string", "example": "New Address"},
                "name": {"type": "string", "example": "Updated Terminal Name"}
              }
            }
          }
        ],
        "responses": {
          "200": {"description": "OK", "schema": {"$ref": "#/definitions/Terminal"}},
          "400": {"description": "Invalid input"},
          "401": {"description": "Unauthorized"},
		"403": {"description": "Forbidden - admin only"},
          "404": {"description": "Terminal not found"}
        }
      },
      "delete": {
        "tags": ["terminals"],
        "summary": "Delete a terminal",
        "description": "Deletes a terminal (admin only)",
        "security": [{"BearerAuth": []}],
        "parameters": [{"in": "path", "name": "id", "required": true, "type": "integer", "description": "Terminal ID"}],
        "responses": {
          "204": {"description": "No Content"},
          "401": {"description": "Unauthorized"},
          "403": {"description": "Forbidden - admin only"},
          "404": {"description": "Terminal not found"}
        }
      }
    },
    "/terminals/authorize": {
      "post": {
        "tags": ["terminal"],
        "summary": "Authorize payment transaction",
        "description": "Authorize a payment transaction from terminal",
        "consumes": ["application/json"],
        "produces": ["application/json"],
        "parameters": [{
          "in": "body",
          "name": "body",
          "required": true,
          "schema": {
            "type": "object",
            "required": ["card_number", "amount", "terminal_id"],
            "properties": {
              "card_number": {"type": "string", "example": "1234567890"},
              "amount": {"type": "integer", "example": 100, "minimum": 1},
              "terminal_id": {"type": "integer", "example": 1, "minimum": 1}
            }
          }
        }],
        "responses": {
          "200": {
            "description": "OK",
            "schema": {
              "type": "object",
              "properties": {
                "status": {"type": "string", "example": "approved"},
                "reason": {"type": "string", "example": ""},
                "balance": {"type": "integer", "example": 900}
              }
            }
          },
          "400": {"description": "Invalid request"},
          "403": {
            "description": "Declined",
            "schema": {
              "type": "object",
              "properties": {
                "status": {"type": "string", "example": "declined"},
                "reason": {"type": "string", "example": "insufficient funds"}
              }
            }
          }
        }
      }
    },
    "/terminals/keys": {
      "get": {
        "tags": ["terminal"],
        "summary": "Get all keys for terminal",
        "description": "Returns all keys for card decryption",
        "security": [{"BearerAuth": []}],
        "responses": {
          "200": {"description": "OK", "schema": {"type": "array", "items": {"$ref": "#/definitions/Key"}}},
          "401": {"description": "Unauthorized"}
        }
      }
    },
    "/transactions": {
      "get": {
        "tags": ["transactions"],
        "summary": "List all transactions",
        "security": [{"BearerAuth": []}],
        "responses": {
          "200": {"description": "OK", "schema": {"type": "array", "items": {"$ref": "#/definitions/Transaction"}}},
          "401": {"description": "Unauthorized"}
        }
      },
      "post": {
        "tags": ["transactions"],
        "summary": "Create a new transaction",
        "description": "Creates a new transaction record (admin only)",
        "security": [{"BearerAuth": []}],
        "consumes": ["application/json"],
        "produces": ["application/json"],
        "parameters": [{
          "in": "body",
          "name": "body",
          "required": true,
          "schema": {
            "type": "object",
            "required": ["amount", "card_id", "terminal_id"],
            "properties": {
              "amount": {"type": "integer", "example": 100, "minimum": 1},
              "card_id": {"type": "integer", "example": 1, "minimum": 1},
              "terminal_id": {"type": "integer", "example": 1, "minimum": 1},
              "created_at": {"type": "string", "example": "17.04.2026 10:30", "description": "Optional. Format: dd.mm.yyyy hh:mm"}
            }
          }
        }],
        "responses": {
          "201": {"description": "Created", "schema": {"$ref": "#/definitions/Transaction"}},
          "400": {"description": "Invalid input"},
          "401": {"description": "Unauthorized"},
          "403": {"description": "Forbidden - admin only"}
        }
      }
    },
    "/transactions/{id}": {
      "get": {
        "tags": ["transactions"],
        "summary": "Get transaction by ID",
        "security": [{"BearerAuth": []}],
        "parameters": [{"in": "path", "name": "id", "required": true, "type": "integer", "description": "Transaction ID"}],
        "responses": {
          "200": {"description": "OK", "schema": {"$ref": "#/definitions/Transaction"}},
          "401": {"description": "Unauthorized"},
          "404": {"description": "Transaction not found"}
        }
      },
      "put": {
        "tags": ["transactions"],
        "summary": "Update a transaction",
        "description": "Updates transaction data (admin only)",
        "security": [{"BearerAuth": []}],
        "consumes": ["application/json"],
        "produces": ["application/json"],
        "parameters": [
          {"in": "path", "name": "id", "required": true, "type": "integer", "description": "Transaction ID"},
          {
            "in": "body",
            "name": "body",
            "required": true,
            "schema": {
              "type": "object",
              "required": ["amount", "card_id", "terminal_id", "created_at"],
              "properties": {
                "amount": {"type": "integer", "example": 150, "minimum": 1},
                "card_id": {"type": "integer", "example": 1},
                "terminal_id": {"type": "integer", "example": 1},
                "created_at": {"type": "string", "example": "17.04.2026 15:45", "description": "Format: dd.mm.yyyy hh:mm"}
              }
            }
          }
        ],
        "responses": {
          "200": {"description": "OK", "schema": {"$ref": "#/definitions/Transaction"}},
          "400": {"description": "Invalid input"},
          "401": {"description": "Unauthorized"},
          "403": {"description": "Forbidden - admin only"},
          "404": {"description": "Transaction not found"}
        }
      },
      "delete": {
        "tags": ["transactions"],
        "summary": "Delete a transaction",
        "description": "Deletes a transaction (admin only)",
        "security": [{"BearerAuth": []}],
        "parameters": [{"in": "path", "name": "id", "required": true, "type": "integer", "description": "Transaction ID"}],
        "responses": {
          "204": {"description": "No Content"},
          "401": {"description": "Unauthorized"},
          "403": {"description": "Forbidden - admin only"},
          "404": {"description": "Transaction not found"}
        }
      }
    },
    "/keys": {
      "get": {
        "tags": ["keys"],
        "summary": "List all keys",
        "security": [{"BearerAuth": []}],
        "responses": {
          "200": {"description": "OK", "schema": {"type": "array", "items": {"$ref": "#/definitions/Key"}}},
          "401": {"description": "Unauthorized"}
        }
      },
      "post": {
        "tags": ["keys"],
        "summary": "Create a new key",
        "description": "Creates a new encryption key (admin only)",
        "security": [{"BearerAuth": []}],
        "consumes": ["application/json"],
        "produces": ["application/json"],
        "parameters": [{
          "in": "body",
          "name": "body",
          "required": true,
          "schema": {
            "type": "object",
            "required": ["data"],
            "properties": {
              "data": {"type": "string", "example": "key_a1b2c3d4e5f6", "minLength": 10}
            }
          }
        }],
        "responses": {
          "201": {"description": "Created", "schema": {"$ref": "#/definitions/Key"}},
          "400": {"description": "Invalid input"},
          "401": {"description": "Unauthorized"},
          "403": {"description": "Forbidden - admin only"}
        }
      }
    },
    "/keys/{id}": {
      "get": {
        "tags": ["keys"],
        "summary": "Get a key by ID",
        "security": [{"BearerAuth": []}],
        "parameters": [{"in": "path", "name": "id", "required": true, "type": "integer", "description": "Key ID"}],
        "responses": {
          "200": {"description": "OK", "schema": {"$ref": "#/definitions/Key"}},
          "401": {"description": "Unauthorized"},
          "404": {"description": "Key not found"}
        }
      },
      "put": {
        "tags": ["keys"],
        "summary": "Update a key",
        "description": "Updates key data (admin only)",
        "security": [{"BearerAuth": []}],
        "consumes": ["application/json"],
        "produces": ["application/json"],
        "parameters": [
          {"in": "path", "name": "id", "required": true, "type": "integer", "description": "Key ID"},
          {
            "in": "body",
            "name": "body",
            "required": true,
            "schema": {
              "type": "object",
              "properties": {
                "data": {"type": "string", "example": "new_key_value"}
              }
            }
          }
        ],
        "responses": {
          "200": {"description": "OK", "schema": {"$ref": "#/definitions/Key"}},
          "400": {"description": "Invalid input"},
          "401": {"description": "Unauthorized"},
          "403": {"description": "Forbidden - admin only"},
          "404": {"description": "Key not found"}
        }
      },
      "delete": {
        "tags": ["keys"],
        "summary": "Delete a key",
        "description": "Deletes a key (admin only)",
        "security": [{"BearerAuth": []}],
        "parameters": [{"in": "path", "name": "id", "required": true, "type": "integer", "description": "Key ID"}],
        "responses": {
          "204": {"description": "No Content"},
          "401": {"description": "Unauthorized"},
          "403": {"description": "Forbidden - admin only"},
          "404": {"description": "Key not found"}
        }
      }
    },
    "/my/card": {
      "get": {
        "tags": ["user"],
        "summary": "Get current user's card",
        "description": "Returns the card associated with the authenticated user (non-admin only)",
        "security": [{"BearerAuth": []}],
        "responses": {
          "200": {"description": "OK", "schema": {"$ref": "#/definitions/Card"}},
          "401": {"description": "Unauthorized"},
          "403": {"description": "Forbidden - admin should use /cards endpoint"},
          "404": {"description": "Card not found for this user"}
        }
      }
    },
    "/my/transactions": {
      "get": {
        "tags": ["user"],
        "summary": "Get current user's transactions",
        "description": "Returns all transactions for the card associated with the authenticated user (non-admin only)",
        "security": [{"BearerAuth": []}],
        "responses": {
          "200": {"description": "OK", "schema": {"type": "array", "items": {"$ref": "#/definitions/Transaction"}}},
          "401": {"description": "Unauthorized"},
          "403": {"description": "Forbidden - admin should use /transactions endpoint"},
          "404": {"description": "No card found for this user"}
        }
      }
    }
  },
  "definitions": {
    "User": {
      "type": "object",
      "properties": {
        "id": {"type": "integer", "example": 1},
        "login": {"type": "string", "example": "admin"},
        "is_admin": {"type": "boolean", "example": true},
        "card_id": {"type": "integer", "example": 1, "description": "Associated card ID (null for admin)"}
      }
    },
    "Card": {
      "type": "object",
      "properties": {
        "id": {"type": "integer", "example": 1},
        "number": {"type": "string", "example": "1234567890"},
        "balance": {"type": "integer", "example": 1000},
        "blocked": {"type": "boolean", "example": false},
        "owner_name": {"type": "string", "example": "Ivan Ivanov"},
        "key_id": {"type": "integer", "example": 1}
      }
    },
    "Terminal": {
      "type": "object",
      "properties": {
        "id": {"type": "integer", "example": 1},
        "serial": {"type": "string", "example": "TERM-001"},
        "address": {"type": "string", "example": "Metro Station 1"},
        "name": {"type": "string", "example": "Metro Terminal"}
      }
    },
    "Transaction": {
      "type": "object",
      "properties": {
        "id": {"type": "integer", "example": 1},
        "amount": {"type": "integer", "example": 100},
        "card_id": {"type": "integer", "example": 1},
        "terminal_id": {"type": "integer", "example": 1},
        "created_at": {"type": "string", "example": "17.04.2026 10:30", "description": "Format: dd.mm.yyyy hh:mm"}
      }
    },
    "Key": {
      "type": "object",
      "properties": {
        "id": {"type": "integer", "example": 1},
        "data": {"type": "string", "example": "key_a1b2c3d4e5f6"}
      }
    }
  },
  "securityDefinitions": {
    "BearerAuth": {
      "type": "apiKey",
      "name": "Authorization",
      "in": "header",
      "description": "JWT Authorization header using the Bearer scheme. Example: 'Bearer {token}'"
    }
  }
}`

// GetSwaggerJSON returns the Swagger JSON specification
func GetSwaggerJSON() []byte {
	return []byte(SwaggerJSON)
}
