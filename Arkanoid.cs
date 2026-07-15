// Arkanoid.cs
using System;
using System.Collections.Generic;
using System.Threading;

class Arkanoid
{
    const int W = 40, H = 20;
    static int paddleX = W / 2 - 4;
    const int paddleWidth = 8;
    static int ballX = paddleX + paddleWidth / 2;
    static int ballY = H - 3;
    static int ballDX = 1;
    static int ballDY = -1;
    static bool ballLaunched = false;
    static int lives = 3;
    static int score = 0;
    static int level = 1;
    static List<(int x, int y, bool alive)> bricks = new List<(int, int, bool)>();
    static bool gameOver = false;
    static bool running = true;

    static void InitBricks()
    {
        bricks.Clear();
        int rows = Math.Min(3 + level, 6);
        int cols = W / 3;
        for (int y = 0; y < rows; y++)
            for (int x = 1; x < cols; x++)
                bricks.Add((x * 3, y + 2, true));
    }

    static void DrawBorder()
    {
        for (int x = 0; x < W; x++)
        {
            Console.SetCursorPosition(x, 0);
            Console.Write('#');
            Console.SetCursorPosition(x, H - 1);
            Console.Write('#');
        }
        for (int y = 0; y < H; y++)
        {
            Console.SetCursorPosition(0, y);
            Console.Write('#');
            Console.SetCursorPosition(W - 1, y);
            Console.Write('#');
        }
    }

    static void DrawPaddle()
    {
        for (int x = 0; x < paddleWidth; x++)
        {
            Console.SetCursorPosition(paddleX + x, H - 2);
            Console.Write('=');
        }
    }

    static void DrawBall()
    {
        if (ballLaunched || !gameOver)
        {
            Console.SetCursorPosition(ballX, ballY);
            Console.Write('O');
        }
    }

    static void DrawBricks()
    {
        foreach (var b in bricks)
            if (b.alive)
            {
                Console.SetCursorPosition(b.x, b.y);
                Console.Write('█');
            }
    }

    static void DrawInfo()
    {
        Console.SetCursorPosition(W + 2, 0);
        Console.Write($"Score: {score}");
        Console.SetCursorPosition(W + 2, 1);
        Console.Write($"Lives: {lives}");
        Console.SetCursorPosition(W + 2, 2);
        Console.Write($"Level: {level}");
        if (gameOver)
        {
            Console.SetCursorPosition(W / 2 - 5, H / 2);
            Console.Write("GAME OVER! Press R");
        }
        else if (!ballLaunched)
        {
            Console.SetCursorPosition(W / 2 - 5, H / 2);
            Console.Write("Press Space to launch");
        }
    }

    static void UpdateBall()
    {
        if (!ballLaunched || gameOver) return;
        ballX += ballDX;
        ballY += ballDY;
        // walls
        if (ballX <= 1 || ballX >= W - 2) ballDX *= -1;
        if (ballY <= 1) ballDY *= -1;
        // paddle
        if (ballY == H - 2 && ballX >= paddleX && ballX < paddleX + paddleWidth)
        {
            ballDY *= -1;
            int hitPos = ballX - (paddleX + paddleWidth / 2);
            if (hitPos != 0)
                ballDX = hitPos > 0 ? 1 : -1;
        }
        // bricks
        for (int i = 0; i < bricks.Count; i++)
        {
            if (bricks[i].alive && ballY == bricks[i].y && ballX == bricks[i].x)
            {
                var b = bricks[i];
                b.alive = false;
                bricks[i] = b;
                score += 10;
                ballDY *= -1;
                break;
            }
        }
        // bottom
        if (ballY >= H - 1)
        {
            lives--;
            ballLaunched = false;
            ballX = paddleX + paddleWidth / 2;
            ballY = H - 3;
            ballDX = new Random().Next(2) == 0 ? 1 : -1;
            ballDY = -1;
            if (lives == 0) gameOver = true;
        }
        // level complete
        bool allDead = true;
        foreach (var b in bricks) if (b.alive) { allDead = false; break; }
        if (allDead)
        {
            level++;
            InitBricks();
            ballLaunched = false;
            ballX = paddleX + paddleWidth / 2;
            ballY = H - 3;
            ballDX = new Random().Next(2) == 0 ? 1 : -1;
            ballDY = -1;
        }
    }

    static void MovePaddle(int dx)
    {
        if (gameOver) return;
        int newX = paddleX + dx;
        if (newX >= 1 && newX + paddleWidth <= W - 1)
        {
            paddleX = newX;
            if (!ballLaunched)
                ballX = paddleX + paddleWidth / 2;
        }
    }

    static void LaunchBall()
    {
        if (gameOver) return;
        if (!ballLaunched) ballLaunched = true;
    }

    static void Restart()
    {
        paddleX = W / 2 - 4;
        ballX = paddleX + paddleWidth / 2;
        ballY = H - 3;
        ballDX = 1;
        ballDY = -1;
        ballLaunched = false;
        lives = 3;
        score = 0;
        level = 1;
        gameOver = false;
        InitBricks();
    }

    static void InputLoop()
    {
        while (running)
        {
            var key = Console.ReadKey(true);
            switch (key.Key)
            {
                case ConsoleKey.R:
                    if (gameOver) Restart();
                    break;
                case ConsoleKey.Spacebar:
                    LaunchBall();
                    break;
                case ConsoleKey.LeftArrow:
                case ConsoleKey.A:
                    MovePaddle(-2);
                    break;
                case ConsoleKey.RightArrow:
                case ConsoleKey.D:
                    MovePaddle(2);
                    break;
                case ConsoleKey.Q:
                    running = false;
                    return;
            }
        }
    }

    static void Main()
    {
        Console.CursorVisible = false;
        InitBricks();
        Thread inputThread = new Thread(InputLoop);
        inputThread.IsBackground = true;
        inputThread.Start();
        while (running)
        {
            UpdateBall();
            Console.Clear();
            DrawBorder();
            DrawPaddle();
            DrawBall();
            DrawBricks();
            DrawInfo();
            Thread.Sleep(50);
        }
    }
}
