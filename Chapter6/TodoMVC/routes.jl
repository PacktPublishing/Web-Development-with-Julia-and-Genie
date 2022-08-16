using Genie
using TodoMVC.TodosController
using SwagUI, SwaggerMarkdown

route("/", TodosController.index)
route("/todos", TodosController.create, method = POST)
route("/todos/:id::Int/toggle", TodosController.toggle, method = POST)
route("/todos/:id::Int/update", TodosController.update, method = POST)
route("/todos/:id::Int/delete", TodosController.delete, method = POST)

# REST API routes:
# route("/api/v1/todos", TodosController.API.V1.list, method = GET)
# route("/api/v1/todos/:id::Int", TodosController.API.V1.item, method = GET)
# route("/api/v1/todos", TodosController.API.V1.create, method = POST)
# route("/api/v1/todos/:id::Int", TodosController.API.V1.update, method = PATCH)
# route("/api/v1/todos/:id::Int", TodosController.API.V1.delete, method = DELETE)

swagger"
/api/v1/todos:
  get:
    summary: Get todos
    description: Get the list of todos items with their status
    parameters:
      - in: query
        name: filter
        description: Todo completed filter with the values 'done' or 'notdone'
        schema:
          type: string
          example: 'done'
      - in: query
        name: page
        description: Page number used for paginating todo items
        schema:
          type: integer
          example: 2
      - in: query
        name: limit
        description: Number of todo items to return per page
        schema:
          type: integer
          example: 10
    responses:
      '200':
        description: A list of todos items
  post:
    summary: Create todo
    description: Create a new todo item
    requestBody:
      description: Todo item to create
      required: true
      content:
        application/json:
          schema:
            type: object
            example:
              todo: Buy milk
              completed: false
    responses:
      '201':
        description: Todo item created
      '400':
        description: Invalid todo item
      '500':
        description: Could not create todo item
"
route("/api/v1/todos", TodosController.API.V1.list, method = GET)
route("/api/v1/todos", TodosController.API.V1.create, method = POST)

swagger"
/api/v1/todos/{id}:
  get:
    summary: Get todo
    description: Get a todo item by id
    parameters:
      - in: path
        name: id
        description: Todo item id
        required: true
        schema:
          type: integer
          example: 1
    responses:
      '200':
        description: A todo item
      '404':
        description: Todo item not found
  patch:
    summary: Update todo
    description: Update a todo item by id
    parameters:
      - in: path
        name: id
        description: Todo item id
        required: true
        schema:
          type: integer
        example: 1
    requestBody:
      description: Todo item to update
      required: true
      content:
        application/json:
          schema:
            type: object
            example:
              todo: Buy milk
              completed: false
    responses:
      '200':
        description: Todo item updated
      '400':
        description: Invalid todo item
      '404':
        description: Todo item not found
      '500':
        description: Could not update todo item
  delete:
    summary: Delete todo
    description: Delete a todo item by id
    parameters:
      - in: path
        name: id
        description: Todo item id
        required: true
        schema:
          type: integer
          example: 1
    responses:
      '200':
        description: Todo item deleted
      '404':
        description: Todo item not found
      '500':
        description: Could not delete todo item
"
route("/api/v1/todos/:id::Int", TodosController.API.V1.item, method = GET)
route("/api/v1/todos/:id::Int", TodosController.API.V1.update, method = PATCH)
route("/api/v1/todos/:id::Int", TodosController.API.V1.delete, method = DELETE)

### Swagger UI route

route("/api/v1/docs") do
  render_swagger(
    build(
      OpenAPI("3.0", Dict("title" => "TodoMVC API", "version" => "1.0.0")),
    ),
    options = Options(
      custom_favicon = "/favicon.ico",
      custom_site_title = "TodoMVC app with Genie",
      show_explorer = false
    )
  )
end