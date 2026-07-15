// arkanoid.js
const readline = require('readline');
const { stdin, stdout } = process;

const W = 40, H = 20;
let paddleX = Math.floor(W/2) - 4;
const paddleWidth = 8;
let ballX = paddleX + Math.floor(paddleWidth/2);
let ballY = H - 3;
let ballDX = 1;
let ballDY = -1;
let ballLaunched = false;
let lives = 3;
let score = 0;
let level = 1;
let bricks = [];
let gameOver = false;
let running = true;

function initBricks() {
    bricks = [];
    const rows = Math.min(3 + level, 6);
    const cols = Math.floor(W / 3);
    for (let y = 0; y < rows; y++) {
        for (let x = 1; x < cols; x++) {
            bricks.push({ x: x * 3, y: y + 2, alive: true });
        }
    }
}

function drawBorder() {
    let out = '';
    for (let x = 0; x < W; x++) out += '#';
    out += '\n';
    for (let y = 1; y < H-1; y++) {
        out += '#';
        for (let x = 1; x < W-1; x++) out += ' ';
        out += '#\n';
    }
    for (let x = 0; x < W; x++) out += '#';
    return out;
}

function render() {
    console.clear();
    // Build grid
    let grid = Array.from({length: H}, () => Array(W).fill(' '));
    // border
    for (let x = 0; x < W; x++) { grid[0][x] = '#'; grid[H-1][x] = '#'; }
    for (let y = 0; y < H; y++) { grid[y][0] = '#'; grid[y][W-1] = '#'; }
    // paddle
    for (let x = 0; x < paddleWidth; x++) {
        grid[H-2][paddleX + x] = '=';
    }
    // ball
    if (ballLaunched || !gameOver) {
        grid[ballY][ballX] = 'O';
    }
    // bricks
    bricks.forEach(b => { if (b.alive) grid[b.y][b.x] = '█'; });
    // print
    console.log(grid.map(row => row.join('')).join('\n'));
    console.log(`Score: ${score}   Lives: ${lives}   Level: ${level}`);
    if (gameOver) console.log('GAME OVER! Press R');
    else if (!ballLaunched) console.log('Press Space to launch');
}

function updateBall() {
    if (!ballLaunched || gameOver) return;
    ballX += ballDX;
    ballY += ballDY;
    // walls
    if (ballX <= 1 || ballX >= W-2) ballDX *= -1;
    if (ballY <= 1) ballDY *= -1;
    // paddle
    if (ballY === H-2 && ballX >= paddleX && ballX < paddleX + paddleWidth) {
        ballDY *= -1;
        const hitPos = ballX - (paddleX + Math.floor(paddleWidth/2));
        if (hitPos !== 0) {
            ballDX = hitPos > 0 ? 1 : -1;
        }
    }
    // bricks
    for (let i = 0; i < bricks.length; i++) {
        if (bricks[i].alive && ballY === bricks[i].y && ballX === bricks[i].x) {
            bricks[i].alive = false;
            score += 10;
            ballDY *= -1;
            break;
        }
    }
    // bottom
    if (ballY >= H-1) {
        lives--;
        ballLaunched = false;
        ballX = paddleX + Math.floor(paddleWidth/2);
        ballY = H - 3;
        ballDX = Math.random() > 0.5 ? 1 : -1;
        ballDY = -1;
        if (lives === 0) gameOver = true;
    }
    // level complete
    if (bricks.every(b => !b.alive)) {
        level++;
        initBricks();
        ballLaunched = false;
        ballX = paddleX + Math.floor(paddleWidth/2);
        ballY = H - 3;
        ballDX = Math.random() > 0.5 ? 1 : -1;
        ballDY = -1;
    }
}

function movePaddle(dx) {
    if (gameOver) return;
    const newX = paddleX + dx;
    if (newX >= 1 && newX + paddleWidth <= W-1) {
        paddleX = newX;
        if (!ballLaunched) {
            ballX = paddleX + Math.floor(paddleWidth/2);
        }
    }
}

function launchBall() {
    if (gameOver) return;
    if (!ballLaunched) ballLaunched = true;
}

function restart() {
    paddleX = Math.floor(W/2) - 4;
    ballX = paddleX + Math.floor(paddleWidth/2);
    ballY = H - 3;
    ballDX = 1;
    ballDY = -1;
    ballLaunched = false;
    lives = 3;
    score = 0;
    level = 1;
    gameOver = false;
    initBricks();
}

function setupInput() {
    readline.emitKeypressEvents(process.stdin);
    process.stdin.setRawMode(true);
    process.stdin.on('keypress', (str, key) => {
        if (key.ctrl && key.name === 'c') process.exit();
        if (key.name === 'q') process.exit();
        if (key.name === 'r' && gameOver) restart();
        if (key.name === 'space') launchBall();
        if (key.name === 'left' || key.name === 'a') movePaddle(-2);
        if (key.name === 'right' || key.name === 'd') movePaddle(2);
    });
}

setupInput();
initBricks();
setInterval(() => {
    updateBall();
    render();
}, 50);
