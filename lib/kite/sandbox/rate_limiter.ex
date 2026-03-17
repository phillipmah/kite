defmodule Kite.Sandbox.RateLimiter do
  @table :sandbox_rate_limiter
  @daily_limit 50

  def setup do
    :ets.new(@table, [:named_table, :public, :set])
    :ok
  end

  @doc """
  Checks if the IP is within the daily limit and increments the counter.
  Returns {:ok, remaining} or {:error, :rate_limited}.
  """
  def check_and_increment(ip) do
    key = {ip, Date.utc_today()}
    count = current_count(ip)

    if count >= @daily_limit do
      {:error, :rate_limited}
    else
      :ets.insert(@table, {key, count + 1})
      {:ok, @daily_limit - count - 1}
    end
  end

  def current_count(ip) do
    key = {ip, Date.utc_today()}

    case :ets.lookup(@table, key) do
      [{^key, count}] -> count
      [] -> 0
    end
  end

  def daily_limit, do: @daily_limit
end
