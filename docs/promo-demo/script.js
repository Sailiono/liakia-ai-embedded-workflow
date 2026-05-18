const terminalRows = Array.from(document.querySelectorAll(".terminal p"));
let activeRow = 0;

function pulseTerminal() {
  terminalRows.forEach((row, index) => {
    row.style.opacity = index <= activeRow ? "1" : "0.42";
    row.style.transform = index === activeRow ? "translateX(4px)" : "translateX(0)";
  });
  activeRow = (activeRow + 1) % terminalRows.length;
}

if (terminalRows.length > 0) {
  pulseTerminal();
  window.setInterval(pulseTerminal, 1050);
}

const stages = [
  {
    kicker: "stage 01 / spec normalization",
    title: "需求规约与约束提取",
    copy: "把客户目标、硬件接口、测试标准和交付格式变成可追踪的工程 spec，避免需求只停留在口头描述。",
    html: `
      <div class="visual tech-visual spec-console">
        <div class="tech-pane spec-source">
          <div class="pane-title">input.yaml</div>
          <pre>project: dpiny-RTK
target: STM32F407VET6
gnss: UM982
links:
  debug: USB_CDC
  data: RS422 x2
validation:
  - build
  - flash
  - shell
  - rtcm_crc</pre>
        </div>
        <div class="tech-pane trace-pane">
          <div class="pane-title">traceability</div>
          <div class="trace-row"><span>REQ-RTK-001</span><strong>RTK base station</strong><em>mapped</em></div>
          <div class="trace-row"><span>IF-UART4</span><strong>GNSS ingress</strong><em>mapped</em></div>
          <div class="trace-row"><span>IF-RS422</span><strong>dual output</strong><em>mapped</em></div>
          <div class="trace-row"><span>VAL-RTCM</span><strong>CRC BAD = 0</strong><em>mapped</em></div>
        </div>
        <div class="tech-pane spec-result">
          <div class="pane-title">normalized_spec.json</div>
          <pre>{
  "mcu": "STM32F407",
  "rtos": "FreeRTOS",
  "baseline": "test-handoff",
  "evidence_required": true
}</pre>
        </div>
      </div>
    `,
    run: runTraceability
  },
  {
    kicker: "stage 02 / task orchestration",
    title: "AI 任务编排与风险闭环",
    copy: "AI 不只是生成代码，而是把固件模块、硬件接口、测试入口和风险点编排成可执行队列。",
    html: `
      <div class="visual tech-visual planner-console">
        <div class="tech-pane planner-board">
          <div class="pane-title">execution graph</div>
          <div class="plan-row"><span>01</span><strong>Core/Src/gnss.c</strong><em>non-blocking init + survey state</em></div>
          <div class="plan-row"><span>02</span><strong>Core/Src/passthrough.c</strong><em>UART4 DMA -> USART1/2</em></div>
          <div class="plan-row"><span>03</span><strong>Core/Src/shell.c</strong><em>operator command surface</em></div>
          <div class="plan-row"><span>04</span><strong>tools/run_test_baseline.ps1</strong><em>evidence runner</em></div>
        </div>
        <div class="tech-pane risk-board">
          <div class="pane-title">risk register</div>
          <table>
            <tr><th>risk</th><th>guard</th><th>status</th></tr>
            <tr class="risk-row"><td>bad baud</td><td>allowlist</td><td>queued</td></tr>
            <tr class="risk-row"><td>rtcm overflow</td><td>ring buffer stats</td><td>queued</td></tr>
            <tr class="risk-row"><td>invalid fixed pos</td><td>range check</td><td>queued</td></tr>
            <tr class="risk-row"><td>field handoff</td><td>summary + manifest</td><td>queued</td></tr>
          </table>
        </div>
      </div>
    `,
    run: runPlanner
  },
  {
    kicker: "stage 03 / build terminal",
    title: "交互式固件编译流",
    copy: "这一段更接近真实开发现场：输入 make 命令并回车，观察构建、链接、产物生成和尺寸摘要的打印流。",
    html: `
      <div class="visual tech-visual build-console">
        <div class="terminal-toolbar">
          <label for="buildCommand">shell</label>
          <div class="command-line">
            <span>$</span>
            <input id="buildCommand" value="make -j8 BUILD=Debug" autocomplete="off" spellcheck="false">
          </div>
        </div>
        <div class="build-log" id="buildLog" aria-live="polite"></div>
        <div class="artifact-strip">
          <div class="artifact-pill" data-artifact="elf"><span>ELF</span><strong>pending</strong></div>
          <div class="artifact-pill" data-artifact="hex"><span>HEX</span><strong>pending</strong></div>
          <div class="artifact-pill" data-artifact="bin"><span>BIN</span><strong>pending</strong></div>
          <div class="artifact-pill" data-artifact="size"><span>SIZE</span><strong>pending</strong></div>
        </div>
      </div>
    `,
    run: runBuildTerminal
  },
  {
    kicker: "stage 04 / hardware interface audit",
    title: "外设接口映射与链路审计",
    copy: "用工程人员熟悉的 pin/peripheral matrix 展示软硬件对齐情况，同时给领导看到接口已经被系统化管理。",
    html: `
      <div class="visual tech-visual interface-console">
        <div class="tech-pane map-table">
          <div class="pane-title">peripheral_map.csv</div>
          <table>
            <tr><th>peripheral</th><th>role</th><th>route</th><th>mode</th></tr>
            <tr class="map-row"><td>UART4</td><td>UM982 ingress</td><td>DMA idle RX</td><td>115200</td></tr>
            <tr class="map-row"><td>USART1</td><td>RS422 out A</td><td>DMA TX</td><td>RTCM</td></tr>
            <tr class="map-row"><td>USART2</td><td>RS422 out B</td><td>DMA TX</td><td>RTCM</td></tr>
            <tr class="map-row"><td>USB FS</td><td>CDC shell</td><td>async write</td><td>debug</td></tr>
          </table>
        </div>
        <div class="tech-pane bus-monitor">
          <div class="pane-title">link monitor</div>
          <div class="metric-row"><span>UART4 RX</span><div><i style="--p: 82%"></i></div><strong>2.0 KB DMA</strong></div>
          <div class="metric-row"><span>PT ring</span><div><i style="--p: 64%"></i></div><strong>8.0 KB</strong></div>
          <div class="metric-row"><span>RS422 A/B</span><div><i style="--p: 74%"></i></div><strong>dual TX</strong></div>
          <div class="metric-row"><span>Watchdog</span><div><i style="--p: 92%"></i></div><strong>fed</strong></div>
        </div>
      </div>
    `,
    run: runInterfaceAudit
  },
  {
    kicker: "stage 05 / validation runner",
    title: "Baseline 测试 Runner",
    copy: "不是展示“测试通过”四个字，而是把环境、烧录、串口、输入校验和 RTCM 解析按真实基线顺序跑出来。",
    html: `
      <div class="visual tech-visual validation-console">
        <div class="runner-grid">
          <div class="test-table">
            <div class="test-line"><span>ENV-02</span><strong>dependency check</strong><em>pending</em></div>
            <div class="test-line"><span>BUILD-01</span><strong>Debug build</strong><em>pending</em></div>
            <div class="test-line"><span>FLASH-01</span><strong>SWD flash + verify</strong><em>pending</em></div>
            <div class="test-line"><span>FUNC-01</span><strong>shell/config/reset</strong><em>pending</em></div>
            <div class="test-line"><span>VAL-05</span><strong>invalid input isolation</strong><em>pending</em></div>
            <div class="test-line"><span>RTCM-02</span><strong>CRC BAD: 0</strong><em>pending</em></div>
          </div>
          <div class="runner-log" id="runnerLog" aria-live="polite"></div>
        </div>
      </div>
    `,
    run: runValidation
  },
  {
    kicker: "stage 06 / evidence manifest",
    title: "交付证据包与 Manifest",
    copy: "最终交付不是一堆散文件，而是可回传、可审计、可复盘的测试结果目录。",
    html: `
      <div class="visual tech-visual manifest-console">
        <div class="tech-pane file-tree">
          <div class="pane-title">build/test-results/20260518-1107</div>
          <pre>summary.md
manifest.json
firmware/
  dpiny-RTK.elf
  dpiny-RTK.hex
  dpiny-RTK.bin
logs/
  01_install_check.log
  02_build.log
  03_flash.log
  04_functional_test.log
  05_input_validation.log
  06_rtcm_parse.log</pre>
        </div>
        <div class="tech-pane manifest-json">
          <div class="pane-title">manifest.json</div>
          <pre>{
  "branch": "baseline/test-handoff",
  "preset": "Debug",
  "firmware": ["elf", "hex", "bin"],
  "logs": 6,
  "rtcm_crc_bad": 0,
  "status": "PASS"
}</pre>
        </div>
        <div class="handoff-checks">
          <div class="hash-row"><span>sha256</span><strong>firmware indexed</strong><em>pending</em></div>
          <div class="hash-row"><span>summary</span><strong>human readable report</strong><em>pending</em></div>
          <div class="hash-row"><span>handoff</span><strong>ready to send</strong><em>pending</em></div>
        </div>
      </div>
    `,
    run: runManifest
  }
];

const stageCards = Array.from(document.querySelectorAll(".stage-card"));
const modulePanel = document.querySelector(".stage-module");
const moduleKicker = document.querySelector("#moduleKicker");
const moduleTitle = document.querySelector("#moduleTitle");
const moduleCopy = document.querySelector("#moduleCopy");
const moduleCanvas = document.querySelector("#moduleCanvas");
const moduleRun = document.querySelector(".module-run");
let activeStage = 0;
let runTimer = 0;
let activeTimers = [];

function clearRunTimers() {
  window.clearTimeout(runTimer);
  activeTimers.forEach((timer) => window.clearTimeout(timer));
  activeTimers = [];
}

function schedule(callback, delay) {
  const timer = window.setTimeout(callback, delay);
  activeTimers.push(timer);
  return timer;
}

function appendLog(target, text, tone = "") {
  if (!target) return;
  const row = document.createElement("div");
  row.className = `log-line ${tone}`.trim();
  row.textContent = text;
  target.appendChild(row);
  target.scrollTop = target.scrollHeight;
}

function streamLog(target, lines, interval = 120) {
  target.textContent = "";
  lines.forEach((line, index) => {
    schedule(() => appendLog(target, line.text, line.tone), index * interval);
  });
}

function markRows(selector, delay = 160) {
  document.querySelectorAll(selector).forEach((row, index) => {
    row.classList.remove("is-done");
    schedule(() => row.classList.add("is-done"), index * delay);
  });
}

function setupCurrentStage() {
  if (activeStage === 2) {
    const input = document.querySelector("#buildCommand");
    input?.addEventListener("focus", () => input.select());
    input?.addEventListener("keydown", (event) => {
      if (event.key === "Enter") {
        event.preventDefault();
        runStage();
      }
    });
  }
}

function renderStage(index, shouldRun = false) {
  clearRunTimers();
  activeStage = index;
  const stage = stages[index];

  stageCards.forEach((card, cardIndex) => {
    const active = cardIndex === index;
    card.classList.toggle("is-active", active);
    card.classList.remove("is-running");
    card.setAttribute("aria-selected", String(active));
  });

  modulePanel.classList.remove("is-running");
  moduleKicker.textContent = stage.kicker;
  moduleTitle.textContent = stage.title;
  moduleCopy.textContent = stage.copy;
  moduleCanvas.innerHTML = stage.html;
  setupCurrentStage();

  if (shouldRun) {
    runStage();
  }
}

function runStage() {
  clearRunTimers();
  modulePanel.classList.remove("is-running");
  stageCards.forEach((card) => card.classList.remove("is-running"));

  void modulePanel.offsetWidth;

  modulePanel.classList.add("is-running");
  stageCards[activeStage]?.classList.add("is-running");
  stages[activeStage]?.run?.();

  runTimer = window.setTimeout(() => {
    modulePanel.classList.remove("is-running");
    stageCards[activeStage]?.classList.remove("is-running");
  }, 5200);
}

function runTraceability() {
  markRows(".trace-row", 180);
}

function runPlanner() {
  markRows(".plan-row", 150);
  markRows(".risk-row", 210);
}

function runBuildTerminal() {
  const input = document.querySelector("#buildCommand");
  const command = input?.value.trim() || "make -j8 BUILD=Debug";
  if (input) input.value = command;

  const log = document.querySelector("#buildLog");
  document.querySelectorAll(".artifact-pill").forEach((pill) => {
    pill.classList.remove("is-done");
    pill.querySelector("strong").textContent = "pending";
  });

  const lines = [
    { text: `$ ${command}`, tone: "cmd" },
    { text: "cmake --preset Debug", tone: "muted" },
    { text: "-- Toolchain: arm-none-eabi-gcc 13.3.1", tone: "muted" },
    { text: "-- Target: STM32F407VET6 / Cortex-M4F", tone: "muted" },
    { text: "[  7%] Building C object Core/Src/main.c.obj" },
    { text: "[ 18%] Building C object Core/Src/gnss.c.obj" },
    { text: "[ 31%] Building C object Core/Src/passthrough.c.obj" },
    { text: "[ 44%] Building C object Core/Src/shell.c.obj" },
    { text: "[ 58%] Building C object Core/Src/config.c.obj" },
    { text: "[ 73%] Building C object USB_DEVICE/App/usbd_cdc_if.c.obj" },
    { text: "[ 86%] Linking C executable dpiny-RTK.elf", tone: "warn" },
    { text: "[ 92%] Generating dpiny-RTK.hex" },
    { text: "[ 96%] Generating dpiny-RTK.bin" },
    { text: "text=117284 data=1688 bss=29120 flash=118972", tone: "ok" },
    { text: "[100%] Built target dpiny-RTK", tone: "ok" }
  ];

  streamLog(log, lines, 145);

  [
    ["elf", "118.9 KB"],
    ["hex", "ready"],
    ["bin", "ready"],
    ["size", "OK"]
  ].forEach(([key, value], index) => {
    schedule(() => {
      const pill = document.querySelector(`[data-artifact="${key}"]`);
      if (!pill) return;
      pill.classList.add("is-done");
      pill.querySelector("strong").textContent = value;
    }, 1800 + index * 360);
  });
}

function runInterfaceAudit() {
  markRows(".map-row", 180);
  document.querySelectorAll(".metric-row i").forEach((bar, index) => {
    bar.style.width = "0";
    schedule(() => {
      bar.style.width = bar.style.getPropertyValue("--p");
    }, 180 + index * 160);
  });
}

function runValidation() {
  const log = document.querySelector("#runnerLog");
  document.querySelectorAll(".test-line").forEach((row) => {
    row.classList.remove("is-done");
    row.querySelector("em").textContent = "pending";
  });

  const lines = [
    { text: "> run_test_baseline.ps1 -Preset Debug -ComPort COM11 -RtcmPort COM6", tone: "cmd" },
    { text: "[ENV-02] CMake / Ninja / Arm GCC / STM32CubeProgrammer detected", tone: "ok" },
    { text: "[BUILD-01] Debug firmware build completed", tone: "ok" },
    { text: "[FLASH-01] SWD download, verify, reset completed", tone: "ok" },
    { text: "[FUNC-01] help/status/config/save/reset PASS", tone: "ok" },
    { text: "[VAL-05] invalid input did not mutate config", tone: "ok" },
    { text: "[RTCM-02] CRC BAD: 0", tone: "ok" },
    { text: "summary.md + manifest.json written", tone: "ok" }
  ];
  streamLog(log, lines, 230);

  document.querySelectorAll(".test-line").forEach((row, index) => {
    schedule(() => {
      row.classList.add("is-done");
      row.querySelector("em").textContent = "PASS";
    }, 420 + index * 360);
  });
}

function runManifest() {
  markRows(".hash-row", 220);
}

stageCards.forEach((card) => {
  card.addEventListener("click", () => renderStage(Number(card.dataset.stage), true));
});

moduleRun?.addEventListener("click", runStage);
moduleCanvas?.addEventListener("click", (event) => {
  if (event.target.closest("input, button, label, .command-line, .build-log, .runner-log")) return;
  runStage();
});

renderStage(0, true);

const cards = document.querySelectorAll(".stage-card, .evidence-grid article, .chip-block");
const observer = new IntersectionObserver((entries) => {
  entries.forEach((entry) => {
    if (entry.isIntersecting) {
      entry.target.classList.add("is-visible");
    }
  });
}, { threshold: 0.2 });

cards.forEach((card) => observer.observe(card));
