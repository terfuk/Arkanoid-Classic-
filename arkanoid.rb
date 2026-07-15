# arkanoid.rb
require 'io/console'
require 'timeout'

W = 40
H = 20

$paddle_x = W/2 - 4
$paddle_width = 8
$ball_x = $paddle_x + $paddle_width/2
$ball_y = H - 3
$ball_dx = 1
$ball_dy = -1
$ball_launched = false
$lives = 3
$score = 0
$level = 1
$bricks = []
$game_over = false
$running = true

def init_bricks
  $bricks = []
  rows = [3 + $level, 6].min
  cols = W / 3
  (0...rows).each do |y|
    (1...cols).each do |x|
      $bricks << {x: x*3, y: y+2, alive: true}
    end
  end
end

def clear_screen
  system('clear') || system('cls')
end

def draw_border
  (0...W).each { |x| print "\e[0;#{x}H#" }
  (0...W).each { |x| print "\e[#{H-1};#{x}H#" }
  (0...H).each { |y| print "\e[#{y};0H#" }
  (0...H).each { |y| print "\e[#{y};#{W-1}H#" }
end

def draw_paddle
  (0...$paddle_width).each { |x| print "\e[#{H-2};#{$paddle_x+x}H=" }
end

def draw_ball
  print "\e[#{$ball_y};#{$ball_x}HO" if $ball_launched || !$game_over
end

def draw_bricks
  $bricks.each do |b|
    print "\e[#{b[:y]};#{b[:x]}H█" if b[:alive]
  end
end

def draw_info
  print "\e[0;#{W+2}HScore: #{$score}"
  print "\e[1;#{W+2}HLives: #{$lives}"
  print "\e[2;#{W+2}HLevel: #{$level}"
  if $game_over
    print "\e[#{H/2};#{W/2-5}HGAME OVER! Press R"
  elsif !$ball_launched
    print "\e[#{H/2};#{W/2-5}HPress Space to launch"
  end
end

def update_ball
  return if !$ball_launched || $game_over
  $ball_x += $ball_dx
  $ball_y += $ball_dy
  # walls
  $ball_dx *= -1 if $ball_x <= 1 || $ball_x >= W-2
  $ball_dy *= -1 if $ball_y <= 1
  # paddle
  if $ball_y == H-2 && $ball_x >= $paddle_x && $ball_x < $paddle_x + $paddle_width
    $ball_dy *= -1
    hit_pos = $ball_x - ($paddle_x + $paddle_width/2)
    if hit_pos != 0
      $ball_dx = hit_pos > 0 ? 1 : -1
    end
  end
  # bricks
  $bricks.each do |b|
    if b[:alive] && $ball_y == b[:y] && $ball_x == b[:x]
      b[:alive] = false
      $score += 10
      $ball_dy *= -1
      break
    end
  end
  # bottom
  if $ball_y >= H-1
    $lives -= 1
    $ball_launched = false
    $ball_x = $paddle_x + $paddle_width/2
    $ball_y = H-3
    $ball_dx = rand(2) == 0 ? 1 : -1
    $ball_dy = -1
    $game_over = true if $lives == 0
  end
  # level complete
  if $bricks.all? { |b| !b[:alive] }
    $level += 1
    init_bricks
    $ball_launched = false
    $ball_x = $paddle_x + $paddle_width/2
    $ball_y = H-3
    $ball_dx = rand(2) == 0 ? 1 : -1
    $ball_dy = -1
  end
end

def move_paddle(dx)
  return if $game_over
  new_x = $paddle_x + dx
  if new_x >= 1 && new_x + $paddle_width <= W-1
    $paddle_x = new_x
    $ball_x = $paddle_x + $paddle_width/2 unless $ball_launched
  end
end

def launch_ball
  return if $game_over
  $ball_launched = true unless $ball_launched
end

def restart
  $paddle_x = W/2 - 4
  $ball_x = $paddle_x + $paddle_width/2
  $ball_y = H-3
  $ball_dx = 1
  $ball_dy = -1
  $ball_launched = false
  $lives = 3
  $score = 0
  $level = 1
  $game_over = false
  init_bricks
end

def input_loop
  while $running
    char = STDIN.getch
    case char
    when 'q', 'Q' then $running = false
    when 'r', 'R'
      restart if $game_over
    when ' ' then launch_ball
    when 'a', 'A' then move_paddle(-2)
    when 'd', 'D' then move_paddle(2)
    when "\e" # arrow keys
      c = STDIN.read_nonblock(2) rescue nil
      if c == '[D' then move_paddle(-2)
      elsif c == '[C' then move_paddle(2)
      end
    end
  end
end

init_bricks
Thread.new { input_loop }
while $running
  update_ball
  clear_screen
  draw_border
  draw_paddle
  draw_ball
  draw_bricks
  draw_info
  sleep 0.05
end
