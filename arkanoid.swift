// arkanoid.swift
import Foundation

let W = 40
let H = 20

var paddleX = W/2 - 4
let paddleWidth = 8
var ballX = paddleX + paddleWidth/2
var ballY = H - 3
var ballDX = 1
var ballDY = -1
var ballLaunched = false
var lives = 3
var score = 0
var level = 1
var bricks: [(x: Int, y: Int, alive: Bool)] = []
var gameOver = false
var running = true

func initBricks() {
    bricks = []
    let rows = min(3 + level, 6)
    let cols = W / 3
    for y in 0..<rows {
        for x in 1..<cols {
            bricks.append((x: x*3, y: y+2, alive: true))
        }
    }
}

func clearScreen() {
    print("\u{001B}[2J")
}

func drawBorder() {
    for x in 0..<W {
        print("\u{001B}[0;\(x)H#", terminator: "")
        print("\u{001B}[\(H-1);\(x)H#", terminator: "")
    }
    for y in 0..<H {
        print("\u{001B}[\(y);0H#", terminator: "")
        print("\u{001B}[\(y);\(W-1)H#", terminator: "")
    }
}

func drawPaddle() {
    for x in 0..<paddleWidth {
        print("\u{001B}[\(H-2);\(paddleX+x)H=", terminator: "")
    }
}

func drawBall() {
    if ballLaunched || !gameOver {
        print("\u{001B}[\(ballY);\(ballX)HO", terminator: "")
    }
}

func drawBricks() {
    for b in bricks {
        if b.alive {
            print("\u{001B}[\(b.y);\(b.x)H█", terminator: "")
        }
    }
}

func drawInfo() {
    print("\u{001B}[0;\(W+2)HScore: \(score)", terminator: "")
    print("\u{001B}[1;\(W+2)HLives: \(lives)", terminator: "")
    print("\u{001B}[2;\(W+2)HLevel: \(level)", terminator: "")
    if gameOver {
        print("\u{001B}[\(H/2);\(W/2-5)HGAME OVER! Press R", terminator: "")
    } else if !ballLaunched {
        print("\u{001B}[\(H/2);\(W/2-5)HPress Space to launch", terminator: "")
    }
}

func updateBall() {
    if !ballLaunched || gameOver { return }
    ballX += ballDX
    ballY += ballDY
    if ballX <= 1 || ballX >= W-2 { ballDX *= -1 }
    if ballY <= 1 { ballDY *= -1 }
    if ballY == H-2 && ballX >= paddleX && ballX < paddleX + paddleWidth {
        ballDY *= -1
        let hitPos = ballX - (paddleX + paddleWidth/2)
        if hitPos != 0 {
            ballDX = hitPos > 0 ? 1 : -1
        }
    }
    for i in 0..<bricks.count {
        if bricks[i].alive && ballY == bricks[i].y && ballX == bricks[i].x {
            bricks[i].alive = false
            score += 10
            ballDY *= -1
            break
        }
    }
    if ballY >= H-1 {
        lives -= 1
        ballLaunched = false
        ballX = paddleX + paddleWidth/2
        ballY = H-3
        ballDX = Int.random(in: 0...1) == 0 ? 1 : -1
        ballDY = -1
        if lives == 0 { gameOver = true }
    }
    if bricks.allSatisfy({ !$0.alive }) {
        level += 1
        initBricks()
        ballLaunched = false
        ballX = paddleX + paddleWidth/2
        ballY = H-3
        ballDX = Int.random(in: 0...1) == 0 ? 1 : -1
        ballDY = -1
    }
}

func movePaddle(dx: Int) {
    if gameOver { return }
    let newX = paddleX + dx
    if newX >= 1 && newX + paddleWidth <= W-1 {
        paddleX = newX
        if !ballLaunched {
            ballX = paddleX + paddleWidth/2
        }
    }
}

func launchBall() {
    if gameOver { return }
    if !ballLaunched { ballLaunched = true }
}

func restart() {
    paddleX = W/2 - 4
    ballX = paddleX + paddleWidth/2
    ballY = H-3
    ballDX = 1
    ballDY = -1
    ballLaunched = false
    lives = 3
    score = 0
    level = 1
    gameOver = false
    initBricks()
}

func inputLoop() {
    while running {
        let input = readLine(strippingNewline: false) ?? ""
        let chars = Array(input)
        if chars.isEmpty { continue }
        let ch = chars[0]
        switch ch {
        case "q", "Q": running = false; return
        case "r", "R":
            if gameOver { restart() }
        case " ":
            launchBall()
        case "a", "A": movePaddle(dx: -2)
        case "d", "D": movePaddle(dx: 2)
        default: break
        }
    }
}

initBricks()
DispatchQueue.global().async {
    inputLoop()
}
while running {
    updateBall()
    clearScreen()
    drawBorder()
    drawPaddle()
    drawBall()
    drawBricks()
    drawInfo()
    Thread.sleep(forTimeInterval: 0.05)
}
