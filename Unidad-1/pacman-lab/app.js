// ─── LAYOUT ───────────────────────────────────────────────────────────────────
// 0 = empty path, 1 = wall, 2 = dot, 3 = power dot, 4 = ghost house
const layout = [
  [1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1],
  [1,2,2,2,2,2,2,2,2,2,2,2,2,1,1,2,2,2,2,2,2,2,2,2,2,2,2,1],
  [1,2,1,1,1,1,2,1,1,1,1,1,2,1,1,2,1,1,1,1,1,2,1,1,1,1,2,1],
  [1,3,1,1,1,1,2,1,1,1,1,1,2,1,1,2,1,1,1,1,1,2,1,1,1,1,3,1],
  [1,2,1,1,1,1,2,1,1,1,1,1,2,1,1,2,1,1,1,1,1,2,1,1,1,1,2,1],
  [1,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,1],
  [1,2,1,1,1,1,2,1,1,2,1,1,1,1,1,1,1,1,2,1,1,2,1,1,1,1,2,1],
  [1,2,1,1,1,1,2,1,1,2,1,1,1,1,1,1,1,1,2,1,1,2,1,1,1,1,2,1],
  [1,2,2,2,2,2,2,1,1,2,2,2,2,1,1,2,2,2,2,1,1,2,2,2,2,2,2,1],
  [1,1,1,1,1,1,2,1,1,1,1,1,0,1,1,0,1,1,1,1,1,2,1,1,1,1,1,1],
  [1,1,1,1,1,1,2,1,1,1,1,1,0,1,1,0,1,1,1,1,1,2,1,1,1,1,1,1],
  [1,1,1,1,1,1,2,1,1,0,0,0,0,0,0,0,0,0,0,1,1,2,1,1,1,1,1,1],
  [1,1,1,1,1,1,2,1,1,0,1,1,1,4,4,1,1,1,0,1,1,2,1,1,1,1,1,1],
  [1,1,1,1,1,1,2,1,1,0,1,4,4,4,4,4,4,1,0,1,1,2,1,1,1,1,1,1],
  [0,0,0,0,0,0,2,0,0,0,1,4,4,4,4,4,4,1,0,0,0,2,0,0,0,0,0,0],
  [1,1,1,1,1,1,2,1,1,0,1,1,1,1,1,1,1,1,0,1,1,2,1,1,1,1,1,1],
  [1,1,1,1,1,1,2,1,1,0,0,0,0,0,0,0,0,0,0,1,1,2,1,1,1,1,1,1],
  [1,1,1,1,1,1,2,1,1,0,1,1,1,1,1,1,1,1,0,1,1,2,1,1,1,1,1,1],
  [1,1,1,1,1,1,2,1,1,0,1,1,1,1,1,1,1,1,0,1,1,2,1,1,1,1,1,1],
  [1,2,2,2,2,2,2,2,2,2,2,2,2,1,1,2,2,2,2,2,2,2,2,2,2,2,2,1],
  [1,2,1,1,1,1,2,1,1,1,1,1,2,1,1,2,1,1,1,1,1,2,1,1,1,1,2,1],
  [1,2,1,1,1,1,2,1,1,1,1,1,2,1,1,2,1,1,1,1,1,2,1,1,1,1,2,1],
  [1,3,2,2,1,1,2,2,2,2,2,2,2,0,0,2,2,2,2,2,2,2,1,1,2,2,3,1],
  [1,1,1,2,1,1,2,1,1,2,1,1,1,1,1,1,1,1,2,1,1,2,1,1,2,1,1,1],
  [1,1,1,2,1,1,2,1,1,2,1,1,1,1,1,1,1,1,2,1,1,2,1,1,2,1,1,1],
  [1,2,2,2,2,2,2,1,1,2,2,2,2,1,1,2,2,2,2,1,1,2,2,2,2,2,2,1],
  [1,2,1,1,1,1,1,1,1,1,1,1,2,1,1,2,1,1,1,1,1,1,1,1,1,1,2,1],
  [1,2,1,1,1,1,1,1,1,1,1,1,2,1,1,2,1,1,1,1,1,1,1,1,1,1,2,1],
  [1,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,1],
  [1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1],
];

const WIDTH = 28;
const grid = document.getElementById('grid');
const scoreEl = document.getElementById('score-count');
const resultEl = document.getElementById('result');

let cells = [];
let score = 0;
let pacmanPos = 434; // row 15, col 14 approx
let gameOver = false;
let powerMode = false;
let powerTimer = null;

// ─── GHOSTS ───────────────────────────────────────────────────────────────────
class Ghost {
  constructor(startPos, cssClass, speed) {
    this.pos = startPos;
    this.cssClass = cssClass;
    this.speed = speed;
    this.interval = null;
    this.scared = false;
  }
  start() {
    this.interval = setInterval(() => this.move(), this.speed);
  }
  stop() { clearInterval(this.interval); }
  move() {
    if (gameOver) return;
    const dirs = [-WIDTH, WIDTH, -1, 1];
    const valid = dirs.filter(d => {
      const next = this.pos + d;
      return next >= 0 && next < cells.length && !cells[next].classList.contains('wall');
    });
    const dir = valid[Math.floor(Math.random() * valid.length)];
    cells[this.pos].classList.remove(this.cssClass, 'ghost', 'ghost-scared');
    this.pos += dir;

    if (this.pos === pacmanPos) {
      if (powerMode) {
        score += 200;
        scoreEl.textContent = score;
        this.pos = 378; // back to ghost house area
      } else {
        endGame(false);
        return;
      }
    }
    cells[this.pos].classList.add('ghost', this.scared ? 'ghost-scared' : this.cssClass);
  }
  scare() {
    this.scared = true;
    cells[this.pos].classList.remove(this.cssClass);
    cells[this.pos].classList.add('ghost-scared');
  }
  unscare() {
    this.scared = false;
    cells[this.pos].classList.remove('ghost-scared');
    cells[this.pos].classList.add(this.cssClass);
  }
}

const ghosts = [
  new Ghost(348, 'ghost-blinky', 300),
  new Ghost(350, 'ghost-pinky',  400),
  new Ghost(376, 'ghost-inky',   500),
  new Ghost(378, 'ghost-clyde',  600),
];

// ─── BUILD GRID ───────────────────────────────────────────────────────────────
function buildGrid() {
  grid.innerHTML = '';
  cells = [];
  layout.forEach((row, r) => {
    row.forEach((val, c) => {
      const cell = document.createElement('div');
      cell.classList.add('cell');
      if (val === 1) cell.classList.add('wall');
      else if (val === 2) cell.classList.add('dot');
      else if (val === 3) cell.classList.add('dot', 'power-dot');
      grid.appendChild(cell);
      cells.push(cell);
    });
  });
  // place pacman
  cells[pacmanPos].classList.add('pacman');
  // place ghosts
  ghosts.forEach(g => cells[g.pos].classList.add('ghost', g.cssClass));
}

// ─── MOVEMENT ─────────────────────────────────────────────────────────────────
function movePacman(dir) {
  if (gameOver) return;
  const next = pacmanPos + dir;
  if (next < 0 || next >= cells.length) return;
  if (cells[next].classList.contains('wall')) return;

  cells[pacmanPos].classList.remove('pacman');
  pacmanPos = next;
  const cell = cells[pacmanPos];

  // eat dot
  if (cell.classList.contains('dot')) {
    const isPower = cell.classList.contains('power-dot');
    cell.classList.remove('dot', 'power-dot');
    score += isPower ? 50 : 10;
    scoreEl.textContent = score;

    if (isPower) activatePowerMode();

    // check win
    if (!document.querySelector('.dot')) endGame(true);
  }

  // check ghost collision
  const hitGhost = ghosts.find(g => g.pos === pacmanPos);
  if (hitGhost) {
    if (powerMode) {
      score += 200;
      scoreEl.textContent = score;
      hitGhost.pos = 378;
    } else {
      endGame(false);
      return;
    }
  }

  cell.classList.add('pacman');
}

function activatePowerMode() {
  powerMode = true;
  ghosts.forEach(g => g.scare());
  clearTimeout(powerTimer);
  powerTimer = setTimeout(() => {
    powerMode = false;
    ghosts.forEach(g => g.unscare());
  }, 8000);
}

// ─── KEYBOARD ─────────────────────────────────────────────────────────────────
document.addEventListener('keydown', e => {
  if (e.key === 'ArrowLeft')  movePacman(-1);
  if (e.key === 'ArrowRight') movePacman(1);
  if (e.key === 'ArrowUp')    movePacman(-WIDTH);
  if (e.key === 'ArrowDown')  movePacman(WIDTH);
});

// ─── END GAME ─────────────────────────────────────────────────────────────────
function endGame(win) {
  gameOver = true;
  ghosts.forEach(g => g.stop());
  resultEl.textContent = win ? '🎉 ¡Ganaste! Score: ' + score : '💀 Game Over! Score: ' + score;
}

// ─── START ────────────────────────────────────────────────────────────────────
buildGrid();
ghosts.forEach(g => g.start());
