// arkanoid.go
package main

import (
	"fmt"
	"math/rand"
	"os"
	"os/exec"
	"time"
)

const (
	width  = 40
	height = 20
)

type Brick struct{ x, y int; alive bool }

var (
	paddleX      = width/2 - 4
	paddleWidth  = 8
	ballX        = paddleX + paddleWidth/2
	ballY        = height - 3
	ballDX       = 1
	ballDY       = -1
	ballLaunched = false
	lives        = 3
	score        = 0
	level        = 1
	bricks       []Brick
	gameOver     = false
	running      = true
)

func clearScreen() {
	cmd := exec.Command("clear")
	cmd.Stdout = os.Stdout
	cmd.Run()
}

func initBricks() {
	bricks = []Brick{}
	rows := 3 + level
	if rows > 6 {
		rows = 6
	}
	cols := width / 3
	for y := 0; y < rows; y++ {
		for x := 1; x < cols; x++ {
			bricks = append(bricks, Brick{x: x * 3, y: y + 2, alive: true})
		}
	}
}

func drawBorder() {
	for x := 0; x < width; x++ {
		fmt.Printf("\033[%d;%dH#", 0, x)
		fmt.Printf("\033[%d;%dH#", height-1, x)
	}
	for y := 0; y < height; y++ {
		fmt.Printf("\033[%d;%dH#", y, 0)
		fmt.Printf("\033[%d;%dH#", y, width-1)
	}
}

func drawPaddle() {
	for x := 0; x < paddleWidth; x++ {
		fmt.Printf("\033[%d;%dH=", height-2, paddleX+x)
	}
}

func drawBall() {
	if ballLaunched || !gameOver {
		fmt.Printf("\033[%d;%dHO", ballY, ballX)
	}
}

func drawBricks() {
	for _, b := range bricks {
		if b.alive {
			fmt.Printf("\033[%d;%dH█", b.y, b.x)
		}
	}
}

func drawInfo() {
	fmt.Printf("\033[%d;%dHScore: %d", 0, width+2, score)
	fmt.Printf("\033[%d;%dHLives: %d", 1, width+2, lives)
	fmt.Printf("\033[%d;%dHLevel: %d", 2, width+2, level)
	if gameOver {
		fmt.Printf("\033[%d;%dHGAME OVER! Press R", height/2, width/2-5)
	} else if !ballLaunched {
		fmt.Printf("\033[%d;%dHPress Space to launch", height/2, width/2-5)
	}
}

func updateBall() {
	if !ballLaunched || gameOver {
		return
	}
	ballX += ballDX
	ballY += ballDY
	// walls
	if ballX <= 1 || ballX >= width-2 {
		ballDX *= -1
	}
	if ballY <= 1 {
		ballDY *= -1
	}
	// paddle
	if ballY == height-2 && ballX >= paddleX && ballX < paddleX+paddleWidth {
		ballDY *= -1
		hitPos := ballX - (paddleX + paddleWidth/2)
		if hitPos != 0 {
			if hitPos > 0 {
				ballDX = 1
			} else {
				ballDX = -1
			}
		}
	}
	// bricks
	for i := range bricks {
		if bricks[i].alive && ballY == bricks[i].y && ballX == bricks[i].x {
			bricks[i].alive = false
			score += 10
			ballDY *= -1
			break
		}
	}
	// bottom
	if ballY >= height-1 {
		lives--
		ballLaunched = false
		ballX = paddleX + paddleWidth/2
		ballY = height - 3
		ballDX = 1
		if rand.Intn(2) == 0 {
			ballDX = -1
		}
		ballDY = -1
		if lives == 0 {
			gameOver = true
		}
	}
	// level complete
	allDead := true
	for _, b := range bricks {
		if b.alive {
			allDead = false
			break
		}
	}
	if allDead {
		level++
		initBricks()
		ballLaunched = false
		ballX = paddleX + paddleWidth/2
		ballY = height - 3
		ballDX = 1
		if rand.Intn(2) == 0 {
			ballDX = -1
		}
		ballDY = -1
	}
}

func movePaddle(dx int) {
	if gameOver {
		return
	}
	newX := paddleX + dx
	if newX >= 1 && newX+paddleWidth <= width-1 {
		paddleX = newX
		if !ballLaunched {
			ballX = paddleX + paddleWidth/2
		}
	}
}

func launchBall() {
	if gameOver {
		return
	}
	if !ballLaunched {
		ballLaunched = true
	}
}

func restart() {
	paddleX = width/2 - 4
	ballX = paddleX + paddleWidth/2
	ballY = height - 3
	ballDX = 1
	ballDY = -1
	ballLaunched = false
	lives = 3
	score = 0
	level = 1
	gameOver = false
	initBricks()
}

func render() {
	clearScreen()
	drawBorder()
	drawPaddle()
	drawBall()
	drawBricks()
	drawInfo()
}

func readInput() {
	go func() {
		for running {
			var b [1]byte
			os.Stdin.Read(b[:])
			switch b[0] {
			case 'q', 'Q':
				running = false
				os.Exit(0)
			case 'r', 'R':
				if gameOver {
					restart()
				}
			case ' ':
				launchBall()
			case 'a', 'A':
				movePaddle(-2)
			case 'd', 'D':
				movePaddle(2)
			}
		}
	}()
}

func main() {
	rand.Seed(time.Now().UnixNano())
	fmt.Print("\033[?25l") // hide cursor
	initBricks()
	readInput()
	for running {
		updateBall()
		render()
		time.Sleep(50 * time.Millisecond)
	}
}
