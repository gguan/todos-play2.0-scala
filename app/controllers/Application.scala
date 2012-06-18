package controllers

import play.api._
import play.api.mvc._
import play.api.data._
import play.api.data.Forms._
import play.api.libs.json.Json._
import models._

object Application extends Controller {

  def index = Action {
    Ok(views.html.index("Todos - Play2.0"))
  }

  def todos = Action { implicit request =>
    Ok(toJson(Todo.all()))
  }

  def add = Action { implicit request =>
    Form("title" -> nonEmptyText).bindFromRequest.fold(
      errors => BadRequest,
      title => {
				Ok(toJson(Todo.create(title)))
      })
  }

  def delete(todo: Long) = Action { implicit request =>
    Todo.delete(todo)
    Ok
  }

  def update(todo: Long) = Action { implicit request =>
    Form("done" -> boolean).bindFromRequest.fold(
    	errors => BadRequest,
			isDone => {
				Todo.markAsDone(todo, isDone)
				Ok
			}
    )
  }

	def rename(todo: Long) = Action { implicit request =>
    Form("title" -> nonEmptyText).bindFromRequest.fold(
    	errors => BadRequest,
			title => {
				Todo.rename(todo, title)
				Ok
			}
    )
  }

	def javascriptRoutes = Action {
		import routes.javascript._
		Ok(
			Routes.javascriptRouter("jsRoutes")(
				controllers.routes.javascript.Application.add, 
				controllers.routes.javascript.Application.update, 
				controllers.routes.javascript.Application.delete, 
				controllers.routes.javascript.Application.rename
			)
		).as("text/javascript")
	}

}