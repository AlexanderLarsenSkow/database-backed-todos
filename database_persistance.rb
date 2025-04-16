require 'pg'

class DatabasePersistance
  attr_reader :db, :logger

  def initialize(logger)
    @db = PG.connect(dbname: 'todos')
    @logger = logger
  end

  def query(statement, *params)
    logger.info "#{statement}: #{params}"
    db.exec_params(statement, params)
  end

  def find_list(id)
    sql = "SELECT * FROM lists WHERE id = $1"
    result = query(sql, id)

    tuple = result.first
		id = tuple['id'].to_i
		todos = load_todo_records(id)
    
		{id: id, name: tuple['name'], todos: todos}
  end

  def all_lists
    sql = "SELECT * FROM lists;"
    result = query(sql)

    result.map do |tuple|
			id = tuple['id'].to_i
			todos = load_todo_records(id)
      {id: id, name: tuple["name"], todos: todos }
    end
  end

  def create_new_list(list_name)
		sql = <<~SQL
			INSERT INTO lists (name)
			VALUES ($1)
			SQL

		query(sql, list_name)	
  end

  def delete_list(id)
		sql = 'DELETE FROM lists WHERE id = $1'
		query(sql, id)
  end

  def update_list_name(id, new_name)
		sql = <<~SQL
			UPDATE lists SET name = $2
			WHERE id = $1	
		SQL

		query(sql, id, new_name)
  end

  def create_new_todo(list_id, todo_name)
		sql = <<~SQL
			INSERT INTO todos (name, list_id)
			VALUES ($2, $1)
		SQL

		query(sql, list_id, todo_name)
  end

  def delete_todo(list_id, todo_id)
		sql = <<~SQL
			DELETE FROM todos
			WHERE list_id = $1 AND id = $2
		SQL

		query(sql, list_id, todo_id)
  end

  def update_todo_status(list_id, todo_id, new_status)
		sql = <<~SQL
			UPDATE todos SET completed = $1
			WHERE list_id = $2 AND id = $3
		SQL

		query(sql, new_status, list_id, todo_id)
  end

  def update_all_todos(list_id)
		sql = 'UPDATE todos SET completed = true WHERE list_id = $1'
		query(sql, list_id)
  end

	private

	def load_todo_records(list_id)
		sql = <<~SQL
		SELECT id, name, completed FROM todos
			WHERE list_id = $1
		SQL

		result = query(sql, list_id)
		result.map do |tuple|
			{ id: tuple['id'].to_i,
				name: tuple['name'], 
				completed: tuple['completed'] == 't' }
		end
	end
end