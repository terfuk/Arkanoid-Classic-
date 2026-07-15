# arkanoid.py
import curses
import random

class Arkanoid:
    def __init__(self, stdscr):
        self.stdscr = stdscr
        curses.curs_set(0)
        self.stdscr.nodelay(1)
        self.stdscr.timeout(50)
        self.height, self.width = self.stdscr.getmaxyx()
        self.width = min(self.width, 80)
        self.height = min(self.height, 24)
        self.paddle_x = self.width // 2 - 4
        self.paddle_width = 8
        self.ball_x = self.paddle_x + self.paddle_width // 2
        self.ball_y = self.height - 3
        self.ball_dx = 1
        self.ball_dy = -1
        self.ball_launched = False
        self.lives = 3
        self.score = 0
        self.level = 1
        self.bricks = []
        self.init_bricks()
        self.game_over = False
        self.paused = False
        self.running = True

    def init_bricks(self):
        self.bricks = []
        rows = min(3 + self.level, 6)
        cols = self.width // 3
        for y in range(rows):
            for x in range(1, cols):
                self.bricks.append([x*3, y+2, 1])  # x, y, alive

    def draw_border(self):
        for x in range(self.width):
            self.stdscr.addch(0, x, '#')
        for y in range(self.height):
            self.stdscr.addch(y, 0, '#')
            self.stdscr.addch(y, self.width-1, '#')

    def draw_paddle(self):
        for x in range(self.paddle_width):
            self.stdscr.addch(self.height-2, self.paddle_x + x, '=')

    def draw_ball(self):
        self.stdscr.addch(self.ball_y, self.ball_x, 'O')

    def draw_bricks(self):
        for x, y, alive in self.bricks:
            if alive:
                self.stdscr.addch(y, x, '█')

    def draw_info(self):
        self.stdscr.addstr(0, self.width+2, f"Score: {self.score}")
        self.stdscr.addstr(1, self.width+2, f"Lives: {self.lives}")
        self.stdscr.addstr(2, self.width+2, f"Level: {self.level}")
        if self.game_over:
            self.stdscr.addstr(self.height//2, self.width//2-5, "GAME OVER! Press R")
        elif not self.ball_launched:
            self.stdscr.addstr(self.height//2, self.width//2-5, "Press Space to launch")

    def update_ball(self):
        if not self.ball_launched or self.game_over:
            return
        self.ball_x += self.ball_dx
        self.ball_y += self.ball_dy
        # Wall collisions
        if self.ball_x <= 1 or self.ball_x >= self.width-2:
            self.ball_dx *= -1
        if self.ball_y <= 1:
            self.ball_dy *= -1
        # Paddle collision
        if self.ball_y == self.height-2 and self.paddle_x <= self.ball_x < self.paddle_x + self.paddle_width:
            self.ball_dy *= -1
            # Angle based on paddle hit position
            hit_pos = self.ball_x - (self.paddle_x + self.paddle_width//2)
            if hit_pos != 0:
                self.ball_dx = 1 if hit_pos > 0 else -1
        # Brick collision
        for i, (x, y, alive) in enumerate(self.bricks):
            if alive and self.ball_y == y and self.ball_x == x:
                self.bricks[i][2] = 0
                self.score += 10
                self.ball_dy *= -1
                break
        # Fall off bottom
        if self.ball_y >= self.height-1:
            self.lives -= 1
            self.ball_launched = False
            self.ball_x = self.paddle_x + self.paddle_width//2
            self.ball_y = self.height-3
            self.ball_dx = random.choice([-1, 1])
            self.ball_dy = -1
            if self.lives == 0:
                self.game_over = True
        # Check if all bricks destroyed
        if not any(alive for _, _, alive in self.bricks):
            self.level += 1
            self.init_bricks()
            self.ball_launched = False
            self.ball_x = self.paddle_x + self.paddle_width//2
            self.ball_y = self.height-3
            self.ball_dx = random.choice([-1, 1])
            self.ball_dy = -1

    def move_paddle(self, dx):
        if self.game_over:
            return
        new_x = self.paddle_x + dx
        if 1 <= new_x and new_x + self.paddle_width <= self.width-1:
            self.paddle_x = new_x
            if not self.ball_launched:
                self.ball_x = self.paddle_x + self.paddle_width//2

    def launch_ball(self):
        if self.game_over:
            return
        if not self.ball_launched:
            self.ball_launched = True

    def restart(self):
        self.__init__(self.stdscr)

    def render(self):
        self.stdscr.clear()
        self.draw_border()
        self.draw_paddle()
        self.draw_ball()
        self.draw_bricks()
        self.draw_info()
        self.stdscr.refresh()

    def run(self):
        while self.running:
            key = self.stdscr.getch()
            if key == ord('q') or key == ord('Q'):
                break
            if key == ord('r') or key == ord('R'):
                self.restart()
            if key == ord(' '):
                self.launch_ball()
            if key == curses.KEY_LEFT or key == ord('a') or key == ord('A'):
                self.move_paddle(-2)
            elif key == curses.KEY_RIGHT or key == ord('d') or key == ord('D'):
                self.move_paddle(2)
            self.update_ball()
            self.render()
            curses.napms(50)

def main(stdscr):
    game = Arkanoid(stdscr)
    game.run()

if __name__ == "__main__":
    curses.wrapper(main)
