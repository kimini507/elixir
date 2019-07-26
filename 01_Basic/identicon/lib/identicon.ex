defmodule Identicon do
  @moduledoc """
    Provides Identicon generation functions
  """

  @doc """
    Generates an identicon given a string
  """
  def generate(input) do
    input
    |> hash_input
    |> pick_color
    |> build_grid
    |> filter_odd_squares
    |> build_pixel_map
    |> draw_image
    |> save_image(input)
  end

  @doc """
    Hashes the input string using `md5`
  """
  def hash_input(input) do
    %Identicon.Image{
      hex: :binary.bin_to_list(:crypto.hash(:md5, input))
    }
  end

  @doc """
    Picks color based on first 3 numbers of the hexed values
  """
  def pick_color(%Identicon.Image{hex: [r, g, b | _tail]} = image) do
    %Identicon.Image{
      image |
      color: {r, g, b}
    }
  end

  @doc """
    Builds the 5x5 image grid based on the hex list
  """
  def build_grid(%Identicon.Image{hex: hex} = image) do
    %Identicon.Image{
      image |
      grid: hex
        |> Enum.chunk_every(3, 3, :discard)
        |> Enum.map(&mirror_row/1)
        |> List.flatten
        |> Enum.with_index
    }
  end

  @doc """
    Mirrors a row (list). Assumes there are only 3 elements in the list

    e.g. [a, b, c] => [a, b, c, b, a]
  """
  def mirror_row([num1, num2, num3] = _row) do
    [num1, num2, num3, num2, num1]
  end

  # def mirror_row([first, second | _tail] = row) do
  #   row ++ [second, first]
  # end

  @doc """
    Filters out non odd (even) valued items in the grid
  """
  def filter_odd_squares(%Identicon.Image{grid: grid} = image) do
    %Identicon.Image{
      image |
      grid: Enum.filter(grid, fn({e, _index} = _e) ->
          rem(e, 2) == 1
        end)
    }
  end

  @doc """
    Builds the pixel map to be rendered in the image.

    Calculates the top left and bottom right pixel positions
    to be drawn using `:egd.filledRectangle`
  """
  def build_pixel_map(%Identicon.Image{grid: grid} = image) do
    %Identicon.Image{
      image |
      pixel_map: Enum.map(grid, fn({_code, index}) ->
          horizontal = rem(index, 5) * 50
          vertical = div(index, 5) * 50

          top_left = {horizontal, vertical}
          bottom_right = {horizontal + 50, vertical + 50}

          {top_left, bottom_right}
        end)
    }
  end

  @doc """
    Renders the image in a 250x250 pixel canvas and plots
    in the colored squares using the `pixel_map` and `color`
  """
  def draw_image(%Identicon.Image{pixel_map: pixel_map, color: color}) do
    image = :egd.create(250, 250)
    fill = :egd.color(color)

    Enum.map(pixel_map, fn({start, stop}) ->
      :egd.filledRectangle(image, start, stop, fill)
    end)

    :egd.render(image)
  end

  @doc """
    Saves an image to the file system
  """
  def save_image(image, filename) do
    File.write("#{filename}.png", image)
  end
end
