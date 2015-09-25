defmodule Elispir do
  def eval(expression, scope \\ %{})

  def eval([:if, conditional, first, second], scope) do
    if eval(conditional, scope), do: eval(first, scope), else: eval(second, scope)
  end

  def eval([:do | expressions], scope) do  # Fix sublime syntax highlighting: |)
    %{last: last, scope: _scope} = Enum.reduce(expressions, %{last: nil, scope: scope}, fn expression, acc ->
      case eval(expression, acc.scope) do
        {value, new_scope} -> %{last: value, scope: Map.merge(acc.scope, new_scope)}
        value -> %{last: value, scope: acc.scope}
      end
    end)
    last
  end

  def eval([:def, variable, value], scope) do
    new_value = eval(value, scope)
    new_scope = Map.put(scope, variable, new_value)
    if is_map(new_value) do
      {"&:#{variable}/#{length new_value.params}", new_scope}
    else
      {new_value, new_scope}
    end
  end

  def eval([:fn, params, body], scope) do
    %{params: params, body: body, closure: scope}
  end

  def eval([expr | args], scope) when is_function(expr) do
    apply(expr, eval(args, scope))
  end

  # We can't match only if `symbol` is defined in the scope, so we have to look ourselves then continue on if it's just a list of variables
  def eval([symbol | args] = list, scope) when is_atom(symbol) do
    case Map.get(scope, symbol) do
      %{params: params, body: body, closure: closure} ->
        new_closure = Map.merge(scope, closure) # scope defined at the time of the function definition overrides current scope
        new_scope = Enum.zip(params, eval(args, new_closure)) |> Enum.into(new_closure)
        eval(body, new_scope)
      nil -> # Missing symbols are assumed to be missing functions, like Elixir
        raise(UndefinedElispirFunctionError, function: symbol)
      _ -> # This wasn't a function after all, simply a list that included an atom as the first element
        eval_list(list, scope)
    end
  end

  def eval(list, scope) when is_list(list), do: eval_list(list, scope)
  def eval(variable, scope) when is_atom(variable), do: Map.get(scope, variable, variable)
  def eval(literal, _scope), do: literal
  
  defp eval_list(list, scope) do
    Enum.map(list, fn arg -> eval(arg, scope) end)
  end
end


defmodule UndefinedElispirFunctionError do
  defexception [:function]

  def message(%{function: function}) do
    "Undefined function: #{function}"
  end
end
