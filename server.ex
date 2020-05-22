defmodule Todo.Server do
  use GenServer, restart: :temporary

  def start_link(name) do
    GenServer.start_link(Todo.Server, name, name: via_tuple(name))
  end
  
  
  def entries(todo_server, date, time) do
    GenServer.call(todo_server, {:entries, date, time})
  end
  
  
  def add_entry(todo_server, new_entry) do
    GenServer.cast(todo_server, {:add_entry, new_entry})
  end
  
  
  def update_entry(todo_server, %{} = new_entry) do
    GenServer.cast(todo_server, {:update_entry, new_entry})
  end
  
  
  def delete_entry(todo_server, entry_id) do
    GenServer.cast(todo_server, {:delete_entry, entry_id})
  end
  
  
  def time_check(todo_server, time) do
    GenServer.call(todo_server, {:time_check, time})
  end
  
  
  def date_check(todo_server, date) do
    GenServer.call(todo_server, {:date_check, date})
  end
  
  
  
  @impl GenServer
  def init(name) do
    IO.puts("Starting to-do server for #{name}")
    {:ok, {name, Todo.Database.get(name) || Todo.List.new()}}
  end
  
  
  @impl GenServer
  def handle_call({:entries, date, time}, _, {name, todo_list}) do
    {:reply, Todo.List.entries(todo_list, date, time),{name, todo_list}}
  end


  @impl GenServer
  def handle_cast({:add_entry, new_entry}, {name, todo_list}) do
    new_list = Todo.List.add_entry(todo_list, new_entry)
    Todo.Database.store(name, new_list)
    {:noreply, {name, new_list}}
  end


  @impl GenServer
  def handle_cast({:update_entry, entry}, {name, todo_list}) do
    {:noreply, name, {Todo.List.update_entry(todo_list, entry)}}
  end
  
  
  @impl GenServer
  def handle_cast({:delete_entry, entry_id}, {name, todo_list}) do
    {:noreply, {name, Todo.List.delete_entry(todo_list, entry_id)}}
  end
  
  
  @impl GenServer
  def handle_call({:time_check, time}, _, {name, todo_list}) do
    {
      :reply,
      Todo.List.time_check(todo_list, time),
      {name, todo_list}
    }
  end


  @impl GenServer
  def handle_call({:date_check, date}, _, {name, todo_list}) do
    {
      :reply,
      Todo.List.date_check(todo_list, date),
      {name, todo_list}
    }
  end
  
  
  
  defp via_tuple(name) do
    Todo.ProcessRegistry.via_tuple({__MODULE__, name})
  end
  
  
  
  @impl GenServer
  def handle_info(:timeout, {name, todo_list}) do
    IO.puts("Stopping to-do server for #{name}")
    {:stop, :normal, {name, todo_list}}
  end
  
  defp expiry_idle_timeout(), do: Application.fetch_env!(:todo, :todo_item_expiry)
end
