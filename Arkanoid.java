// Arkanoid.java
import java.awt.*;
import java.awt.event.*;
import javax.swing.*;
import java.util.*;

class Arkanoid extends JPanel implements ActionListener, KeyListener {
    static final int W = 40, H = 20, CELL = 20;
    int paddleX = W/2 - 4;
    final int paddleWidth = 8;
    int ballX = paddleX + paddleWidth/2;
    int ballY = H - 3;
    int ballDX = 1;
    int ballDY = -1;
    boolean ballLaunched = false;
    int lives = 3;
    int score = 0;
    int level = 1;
    java.util.List<Brick> bricks = new ArrayList<>();
    boolean gameOver = false;
    boolean paused = false;
    Timer timer;

    class Brick { int x, y; boolean alive; Brick(int x, int y) { this.x=x; this.y=y; alive=true; } }

    public Arkanoid() {
        setPreferredSize(new Dimension(W*CELL + 150, H*CELL));
        setBackground(Color.BLACK);
        setFocusable(true);
        addKeyListener(this);
        initBricks();
        timer = new Timer(50, this);
        timer.start();
    }

    void initBricks() {
        bricks.clear();
        int rows = Math.min(3 + level, 6);
        int cols = W / 3;
        for (int y = 0; y < rows; y++)
            for (int x = 1; x < cols; x++)
                bricks.add(new Brick(x*3, y+2));
    }

    void updateBall() {
        if (!ballLaunched || gameOver) return;
        ballX += ballDX;
        ballY += ballDY;
        if (ballX <= 1 || ballX >= W-2) ballDX *= -1;
        if (ballY <= 1) ballDY *= -1;
        if (ballY == H-2 && ballX >= paddleX && ballX < paddleX + paddleWidth) {
            ballDY *= -1;
            int hitPos = ballX - (paddleX + paddleWidth/2);
            if (hitPos != 0) ballDX = hitPos > 0 ? 1 : -1;
        }
        for (Brick b : bricks) {
            if (b.alive && ballY == b.y && ballX == b.x) {
                b.alive = false;
                score += 10;
                ballDY *= -1;
                break;
            }
        }
        if (ballY >= H-1) {
            lives--;
            ballLaunched = false;
            ballX = paddleX + paddleWidth/2;
            ballY = H-3;
            ballDX = new Random().nextBoolean() ? 1 : -1;
            ballDY = -1;
            if (lives == 0) gameOver = true;
        }
        boolean allDead = true;
        for (Brick b : bricks) if (b.alive) { allDead = false; break; }
        if (allDead) {
            level++;
            initBricks();
            ballLaunched = false;
            ballX = paddleX + paddleWidth/2;
            ballY = H-3;
            ballDX = new Random().nextBoolean() ? 1 : -1;
            ballDY = -1;
        }
    }

    void movePaddle(int dx) {
        if (gameOver) return;
        int newX = paddleX + dx;
        if (newX >= 1 && newX + paddleWidth <= W-1) {
            paddleX = newX;
            if (!ballLaunched) ballX = paddleX + paddleWidth/2;
        }
    }

    void launchBall() {
        if (gameOver) return;
        if (!ballLaunched) ballLaunched = true;
    }

    void restart() {
        paddleX = W/2 - 4;
        ballX = paddleX + paddleWidth/2;
        ballY = H-3;
        ballDX = 1;
        ballDY = -1;
        ballLaunched = false;
        lives = 3;
        score = 0;
        level = 1;
        gameOver = false;
        initBricks();
    }

    @Override public void actionPerformed(ActionEvent e) {
        updateBall();
        repaint();
    }

    @Override public void paintComponent(Graphics g) {
        super.paintComponent(g);
        g.setColor(Color.WHITE);
        // border
        for (int x = 0; x < W; x++) {
            g.drawRect(x*CELL, 0, CELL, CELL);
            g.drawRect(x*CELL, (H-1)*CELL, CELL, CELL);
        }
        for (int y = 0; y < H; y++) {
            g.drawRect(0, y*CELL, CELL, CELL);
            g.drawRect((W-1)*CELL, y*CELL, CELL, CELL);
        }
        // paddle
        g.setColor(Color.BLUE);
        g.fillRect(paddleX*CELL, (H-2)*CELL, paddleWidth*CELL, CELL);
        // ball
        g.setColor(Color.YELLOW);
        g.fillOval(ballX*CELL, ballY*CELL, CELL, CELL);
        // bricks
        g.setColor(Color.RED);
        for (Brick b : bricks)
            if (b.alive)
                g.fillRect(b.x*CELL, b.y*CELL, CELL, CELL);
        // info
        g.setColor(Color.WHITE);
        g.drawString("Score: "+score, W*CELL+10, 20);
        g.drawString("Lives: "+lives, W*CELL+10, 40);
        g.drawString("Level: "+level, W*CELL+10, 60);
        if (gameOver) {
            g.setColor(Color.RED);
            g.setFont(new Font("Arial", Font.BOLD, 30));
            g.drawString("GAME OVER", W*CELL/2-50, H*CELL/2);
        } else if (!ballLaunched) {
            g.setColor(Color.GREEN);
            g.drawString("Press SPACE", W*CELL/2-40, H*CELL/2);
        }
    }

    @Override public void keyPressed(KeyEvent e) {
        int key = e.getKeyCode();
        if (key == KeyEvent.VK_R && gameOver) restart();
        if (key == KeyEvent.VK_SPACE) launchBall();
        if (key == KeyEvent.VK_LEFT || key == KeyEvent.VK_A) movePaddle(-2);
        if (key == KeyEvent.VK_RIGHT || key == KeyEvent.VK_D) movePaddle(2);
        if (key == KeyEvent.VK_Q) System.exit(0);
    }
    @Override public void keyReleased(KeyEvent e) {}
    @Override public void keyTyped(KeyEvent e) {}

    public static void main(String[] args) {
        JFrame frame = new JFrame("Arkanoid");
        frame.setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
        frame.setResizable(false);
        frame.add(new Arkanoid());
        frame.pack();
        frame.setLocationRelativeTo(null);
        frame.setVisible(true);
    }
}
