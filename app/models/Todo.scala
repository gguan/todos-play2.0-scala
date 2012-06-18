package models

import play.api.db._
import play.api.Play.current

import anorm._
import anorm.SqlParser._
import play.api.libs.json._

case class Todo(id: Pk[Long], title: String, done: Boolean, index: Int)

object Todo {

  val todo = {
    get[Pk[Long]]("todo_item.id") ~
    get[String]("todo_item.title") ~
    get[Boolean]("todo_item.done") ~
    get[Int]("todo_item.index") map {
    	case id~title~done~index => Todo(id, title, done, index)
    }
  }

  implicit object TodoFormat extends Format[Todo] {
    def reads(json: JsValue): Todo = Todo(
      Id((json \ "id").as[String].toLong),
      (json \ "title").as[String],
      (json \ "done").as[Boolean],
      (json \ "index").as[Int])
    def writes(p: Todo): JsValue = JsObject(Seq(
      "id" -> JsNumber(p.id.get),
      "title" -> JsString(p.title),
      "done" -> JsBoolean(p.done),
      "index" -> JsNumber(p.index)))
  }

  def all(): List[Todo] = DB.withConnection { implicit c =>
    SQL("select * from todo_item").as(todo *)
  }

  def create(title: String): Todo = {
    DB.withConnection { implicit c =>
	
			val id: Long = {
				SQL("select next value for todo_item_seq").as(scalar[Long].single)
			}
			
      SQL("insert into todo_item values ({id}, {title}, {done}, {index})").on(
        'id -> id,
				'title -> title,
        'done -> false,
        'index -> 0).executeUpdate()
			
			Todo(Id(id), title, false, 0)
    }
		
		
  }

  def markAsDone(todoId: Long, done: Boolean) {
    DB.withConnection { implicit c =>
      SQL("update todo_item set done = {done} where id = {id}").on(
        'id -> todoId,
        'done -> done).executeUpdate()
    }
  }

  def rename(todoId: Long, title: String) {
    DB.withConnection { implicit c =>
      SQL("update todo_item set title = {title} where id = {id}").on(
        'id -> todoId,
        'title -> title).executeUpdate()
    }
  }

  def delete(id: Long) {
    DB.withConnection { implicit c =>
      SQL("delete from todo_item where id = {id}").on(
        'id -> id).executeUpdate()
    }
  }
}