#!/usr/bin/env node

import { mkdir, readdir, readFile, writeFile } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";

const scriptPath = fileURLToPath(import.meta.url);
const linearDir = path.resolve(path.dirname(scriptPath), "..");
const workplansDir = path.join(linearDir, "workplans");
const generatedDir = path.join(linearDir, ".generated");
const outputPath = path.join(generatedDir, "workplan.html");
const generatedGitignorePath = path.join(generatedDir, ".gitignore");

const palette = [
  "#2563eb",
  "#059669",
  "#dc2626",
  "#d97706",
  "#0891b2",
  "#7c3aed",
  "#be123c",
  "#4d7c0f",
  "#0f766e",
  "#9333ea",
];

async function main() {
  const yamlFiles = (await readdir(workplansDir))
    .filter((file) => file.endsWith(".yaml"))
    .sort();

  if (yamlFiles.length === 0) {
    throw new Error(`No workplan YAML files found in ${workplansDir}`);
  }

  const workplans = await Promise.all(
    yamlFiles.map(async (file) => {
      const absolutePath = path.join(workplansDir, file);
      const source = await readFile(absolutePath, "utf8");
      return {
        file,
        document: parseYamlSubset(source, absolutePath),
      };
    }),
  );

  const model = buildModel(workplans);
  const html = renderHtml(model);

  await mkdir(generatedDir, { recursive: true });
  await writeFile(generatedGitignorePath, "*\n!.gitignore\n", "utf8");
  await writeFile(outputPath, html, "utf8");

  console.log(`generated ${path.relative(process.cwd(), outputPath)}`);
  console.log(
    `files=${model.summary.fileCount}, tasks=${model.summary.taskCount}, dependencies=${model.summary.dependencyCount}`,
  );
}

function buildModel(workplans) {
  const milestoneTitles = new Map();
  const tasks = [];

  for (const workplan of workplans) {
    for (const milestone of workplan.document.milestones ?? []) {
      milestoneTitles.set(milestone.id, milestone.title ?? milestone.id);
    }

    const defaults = workplan.document.defaults ?? {};
    for (const task of workplan.document.tasks ?? []) {
      const labels = unique([...(defaults.labels ?? []), ...(task.labels ?? [])]);
      tasks.push({
        local_id: String(task.local_id),
        title: task.title ?? "",
        description: task.description ?? "",
        depends_on: task.depends_on ?? [],
        milestone: task.milestone ?? "",
        milestone_title: milestoneTitles.get(task.milestone) ?? task.milestone ?? "미지정",
        labels,
        done_when: task.done_when ?? [],
        evidence: task.evidence ?? [],
        metrics: task.metrics ?? [],
        source_file: workplan.file,
      });
    }
  }

  const idCounts = new Map();
  for (const task of tasks) {
    idCounts.set(task.local_id, (idCounts.get(task.local_id) ?? 0) + 1);
  }
  const duplicateIds = [...idCounts.entries()]
    .filter(([, count]) => count > 1)
    .map(([id]) => id);

  const taskById = new Map(tasks.map((task) => [task.local_id, task]));
  const missingDependencies = [];
  const edges = [];
  const outgoing = new Map(tasks.map((task) => [task.local_id, []]));
  const incoming = new Map(tasks.map((task) => [task.local_id, []]));

  for (const task of tasks) {
    for (const dependency of task.depends_on) {
      if (!taskById.has(dependency)) {
        missingDependencies.push({ task_id: task.local_id, missing_id: dependency });
        continue;
      }
      edges.push({ source: dependency, target: task.local_id });
      outgoing.get(dependency).push(task.local_id);
      incoming.get(task.local_id).push(dependency);
    }
  }

  const cycle = findCycle(tasks, taskById);
  const milestones = [...new Set(tasks.map((task) => task.milestone || "미지정"))];
  const milestoneColors = new Map(
    milestones.map((milestone, index) => [milestone, palette[index % palette.length]]),
  );
  const labels = [...new Set(tasks.flatMap((task) => task.labels))].sort();
  const startingTasks = tasks.filter((task) => task.depends_on.length === 0);
  const bottlenecks = findBottlenecks(tasks, outgoing).slice(0, 12);

  return {
    generatedAt: new Date().toISOString(),
    summary: {
      fileCount: workplans.length,
      taskCount: tasks.length,
      dependencyCount: tasks.reduce((total, task) => total + task.depends_on.length, 0),
      duplicateIds,
      missingDependencies,
      cycle,
    },
    files: workplans.map((workplan) => workplan.file),
    milestones: milestones.map((milestone) => ({
      id: milestone,
      title: milestoneTitles.get(milestone) ?? milestone,
      color: milestoneColors.get(milestone),
    })),
    labels,
    tasks: tasks.map((task) => ({
      ...task,
      color: milestoneColors.get(task.milestone || "미지정"),
      unblocks_direct: outgoing.get(task.local_id)?.length ?? 0,
      blocked_by_direct: incoming.get(task.local_id)?.length ?? 0,
    })),
    edges,
    startingTasks,
    bottlenecks,
  };
}

function findCycle(tasks, taskById) {
  const temporary = new Set();
  const permanent = new Set();
  let cycle = [];

  function visit(id, stack) {
    if (cycle.length > 0 || permanent.has(id) || !taskById.has(id)) {
      return;
    }
    if (temporary.has(id)) {
      cycle = [...stack, id];
      return;
    }
    temporary.add(id);
    for (const dependency of taskById.get(id).depends_on ?? []) {
      visit(dependency, [...stack, id]);
    }
    temporary.delete(id);
    permanent.add(id);
  }

  for (const task of tasks) {
    visit(task.local_id, []);
  }
  return cycle;
}

function findBottlenecks(tasks, outgoing) {
  const taskById = new Map(tasks.map((task) => [task.local_id, task]));

  function collectUnblocked(id, seen = new Set()) {
    for (const next of outgoing.get(id) ?? []) {
      if (seen.has(next)) {
        continue;
      }
      seen.add(next);
      collectUnblocked(next, seen);
    }
    return seen;
  }

  return tasks
    .map((task) => ({
      ...task,
      unblocks_direct: outgoing.get(task.local_id)?.length ?? 0,
      unblocks_total: collectUnblocked(task.local_id).size,
    }))
    .filter((task) => task.unblocks_total > 0 && taskById.has(task.local_id))
    .sort(
      (left, right) =>
        right.unblocks_total - left.unblocks_total ||
        right.unblocks_direct - left.unblocks_direct ||
        left.local_id.localeCompare(right.local_id),
    );
}

function parseYamlSubset(source, filePath) {
  const lines = source.replace(/\r\n/g, "\n").split("\n");
  const context = { filePath, lines };
  const [document] = parseBlock(context, 0, 0);
  return document ?? {};
}

function parseBlock(context, index, indent) {
  index = skipBlankAndCommentLines(context, index);
  if (index >= context.lines.length) {
    return [null, index];
  }

  const line = readLine(context, index);
  if (line.indent < indent) {
    return [null, index];
  }
  if (line.content.startsWith("- ")) {
    return parseSequence(context, index, line.indent);
  }
  return parseMapping(context, index, line.indent);
}

function parseMapping(context, index, indent) {
  const result = {};

  while (index < context.lines.length) {
    index = skipBlankAndCommentLines(context, index);
    if (index >= context.lines.length) {
      break;
    }

    const line = readLine(context, index);
    if (line.indent < indent || line.content.startsWith("- ")) {
      break;
    }
    if (line.indent > indent) {
      throw parseError(context, index, `Unexpected indentation. Expected ${indent} spaces.`);
    }

    const { key, rest } = parseKeyValue(context, index, line.content);
    index += 1;

    if (isLiteralBlock(rest)) {
      const [value, nextIndex] = collectLiteralBlock(context, index, line.indent);
      result[key] = value;
      index = nextIndex;
      continue;
    }

    if (rest.trim() !== "") {
      result[key] = parseScalar(rest.trim());
      continue;
    }

    const nextIndex = skipBlankAndCommentLines(context, index);
    const nextLine = nextIndex < context.lines.length ? readLine(context, nextIndex) : null;
    if (
      nextLine === null ||
      nextLine.indent < line.indent ||
      (nextLine.indent === line.indent && !nextLine.content.startsWith("- "))
    ) {
      result[key] = null;
      index = nextIndex;
      continue;
    }

    const [value, afterNested] = parseBlock(context, nextIndex, nextLine.indent);
    result[key] = value;
    index = afterNested;
  }

  return [result, index];
}

function parseSequence(context, index, indent) {
  const result = [];

  while (index < context.lines.length) {
    index = skipBlankAndCommentLines(context, index);
    if (index >= context.lines.length) {
      break;
    }

    const line = readLine(context, index);
    if (line.indent !== indent || !line.content.startsWith("- ")) {
      break;
    }

    const item = line.content.slice(2).trimEnd();
    index += 1;

    if (item === "") {
      const [value, nextIndex] = parseBlock(context, index, indent + 2);
      result.push(value);
      index = nextIndex;
      continue;
    }

    if (looksLikeKeyValue(item)) {
      const { key, rest } = parseKeyValue(context, index - 1, item);
      const object = {};

      if (isLiteralBlock(rest)) {
        const [value, nextIndex] = collectLiteralBlock(context, index, indent + 2);
        object[key] = value;
        index = nextIndex;
      } else if (rest.trim() === "") {
        const nextIndex = skipBlankAndCommentLines(context, index);
        if (nextIndex < context.lines.length && readLine(context, nextIndex).indent > indent) {
          const [value, afterNested] = parseBlock(
            context,
            nextIndex,
            readLine(context, nextIndex).indent,
          );
          object[key] = value;
          index = afterNested;
        } else {
          object[key] = null;
          index = nextIndex;
        }
      } else {
        object[key] = parseScalar(rest.trim());
      }

      const nextIndex = skipBlankAndCommentLines(context, index);
      if (
        nextIndex < context.lines.length &&
        readLine(context, nextIndex).indent === indent + 2 &&
        !readLine(context, nextIndex).content.startsWith("- ")
      ) {
        const [extraFields, afterExtraFields] = parseMapping(context, nextIndex, indent + 2);
        Object.assign(object, extraFields);
        index = afterExtraFields;
      }

      result.push(object);
      continue;
    }

    result.push(parseScalar(item));
  }

  return [result, index];
}

function collectLiteralBlock(context, index, parentIndent) {
  const lines = [];

  while (index < context.lines.length) {
    const rawLine = context.lines[index];
    const indent = rawLine.match(/^ */)[0].length;

    if (rawLine.trim() !== "" && indent <= parentIndent) {
      break;
    }

    const stripIndent = Math.min(indent, parentIndent + 2);
    lines.push(rawLine.slice(stripIndent).replace(/\s+$/u, ""));
    index += 1;
  }

  return [lines.join("\n").replace(/\n*$/u, "\n"), index];
}

function readLine(context, index) {
  const raw = context.lines[index];
  const indent = raw.match(/^ */)[0].length;
  return {
    indent,
    content: raw.slice(indent).trimEnd(),
  };
}

function skipBlankAndCommentLines(context, index) {
  while (index < context.lines.length) {
    const trimmed = context.lines[index].trim();
    if (trimmed !== "" && !trimmed.startsWith("#")) {
      break;
    }
    index += 1;
  }
  return index;
}

function parseKeyValue(context, index, content) {
  const match = content.match(/^((?:"[^"]+")|(?:'[^']+')|[^:]+):(.*)$/u);
  if (!match) {
    throw parseError(context, index, `Expected key/value pair: ${content}`);
  }
  return {
    key: stripQuotes(match[1].trim()),
    rest: match[2],
  };
}

function looksLikeKeyValue(value) {
  return /^((?:"[^"]+")|(?:'[^']+')|[^:]+):/u.test(value);
}

function isLiteralBlock(value) {
  return value.trim().startsWith("|");
}

function parseScalar(value) {
  if (value === "[]") {
    return [];
  }
  if (value === "null" || value === "~") {
    return null;
  }
  if (/^-?\d+(\.\d+)?$/u.test(value)) {
    return Number(value);
  }
  if (value === "true") {
    return true;
  }
  if (value === "false") {
    return false;
  }
  return stripQuotes(value);
}

function stripQuotes(value) {
  if (
    (value.startsWith('"') && value.endsWith('"')) ||
    (value.startsWith("'") && value.endsWith("'"))
  ) {
    return value.slice(1, -1);
  }
  return value;
}

function parseError(context, index, message) {
  return new Error(`${context.filePath}:${index + 1}: ${message}`);
}

function unique(values) {
  return [...new Set(values.filter((value) => value !== null && value !== undefined))];
}

function renderHtml(model) {
  const json = JSON.stringify(model)
    .replace(/</gu, "\\u003c")
    .replace(/>/gu, "\\u003e")
    .replace(/&/gu, "\\u0026");

  return `<!doctype html>
<html lang="ko">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Linear Workplan DAG</title>
  <style>
    :root {
      --bg: #f7f3ea;
      --panel: #fffaf1;
      --ink: #1f2933;
      --muted: #697386;
      --line: #d8cec0;
      --accent: #0f766e;
      --danger: #b91c1c;
      --ok: #047857;
      --shadow: 0 18px 45px rgba(31, 41, 51, 0.12);
    }
    * {
      box-sizing: border-box;
    }
    body {
      margin: 0;
      color: var(--ink);
      background:
        radial-gradient(circle at 15% 12%, rgba(15, 118, 110, 0.14), transparent 26rem),
        linear-gradient(135deg, #f7f3ea 0%, #eef6f4 52%, #fff7ed 100%);
      font-family: Avenir Next, Optima, Candara, Segoe UI, sans-serif;
    }
    header {
      padding: 28px clamp(18px, 4vw, 44px) 18px;
    }
    h1 {
      margin: 0 0 8px;
      font-size: clamp(28px, 4vw, 48px);
      line-height: 1.05;
      letter-spacing: 0;
    }
    .lede {
      max-width: 920px;
      margin: 0;
      color: var(--muted);
      font-size: 16px;
      line-height: 1.7;
    }
    .stats {
      display: grid;
      grid-template-columns: repeat(6, minmax(120px, 1fr));
      gap: 10px;
      padding: 0 clamp(18px, 4vw, 44px) 18px;
    }
    .stat {
      min-height: 90px;
      border: 1px solid var(--line);
      border-radius: 8px;
      background: rgba(255, 250, 241, 0.82);
      box-shadow: var(--shadow);
      padding: 14px;
    }
    .stat strong {
      display: block;
      margin-top: 8px;
      font-size: 26px;
      line-height: 1;
    }
    .stat span {
      color: var(--muted);
      font-size: 13px;
    }
    .stat.ok strong {
      color: var(--ok);
    }
    .stat.warn strong {
      color: var(--danger);
    }
    .layout {
      display: grid;
      grid-template-columns: 1fr;
      gap: 18px;
      padding-inline: clamp(10px, 2vw, 24px);
    }
    .graph-panel,
    .side-panel,
    .list-panel {
      min-width: 0;
      border: 1px solid var(--line);
      border-radius: 8px;
      background: rgba(255, 250, 241, 0.9);
      box-shadow: var(--shadow);
    }
    .toolbar {
      display: flex;
      flex-wrap: wrap;
      gap: 10px;
      align-items: center;
      padding: 12px;
      border-bottom: 1px solid var(--line);
    }
    label {
      color: var(--muted);
      font-size: 13px;
      font-weight: 700;
    }
    select,
    button {
      min-height: 36px;
      border: 1px solid #b7aa99;
      border-radius: 8px;
      background: #fffdf8;
      color: var(--ink);
      font: inherit;
      padding: 7px 10px;
    }
    button {
      cursor: pointer;
    }
    button.active {
      border-color: var(--accent);
      background: #dff4ef;
      color: #064e3b;
    }
    #graph {
      width: 100%;
      height: min(84vh, 920px);
      min-height: 640px;
      overflow: hidden;
      background:
        linear-gradient(rgba(31, 41, 51, 0.04) 1px, transparent 1px),
        linear-gradient(90deg, rgba(31, 41, 51, 0.04) 1px, transparent 1px);
      background-size: 32px 32px;
      cursor: grab;
      user-select: none;
      touch-action: none;
    }
    #graph.is-panning {
      cursor: grabbing;
    }
    #graph svg {
      display: block;
      min-width: 100%;
    }
    .graph-edge {
      stroke: #8a7d6b;
      stroke-width: 1.5;
      fill: none;
      opacity: 0.82;
    }
    .graph-node {
      cursor: pointer;
    }
    .graph-node circle {
      stroke: #111827;
      stroke-width: 1.3;
    }
    .graph-node text {
      fill: #111827;
      font-size: 11px;
      font-weight: 700;
      paint-order: stroke;
      stroke: #fffaf1;
      stroke-width: 4px;
      stroke-linejoin: round;
    }
    .graph-node .node-id {
      fill: #4b5563;
      font-size: 9px;
      font-weight: 700;
    }
    .graph-node.selected circle {
      stroke-width: 4;
    }
    .dimmed {
      opacity: 0.12;
    }
    .side-panel {
      overflow: hidden;
    }
    .detail,
    .list-panel {
      padding: 16px;
    }
    .detail h2,
    .list-panel h2 {
      margin: 0 0 10px;
      font-size: 20px;
    }
    .meta {
      display: flex;
      flex-wrap: wrap;
      gap: 6px;
      margin: 10px 0;
    }
    .pill {
      display: inline-flex;
      align-items: center;
      min-height: 26px;
      border-radius: 999px;
      background: #eef2f7;
      color: #354052;
      padding: 4px 9px;
      font-size: 12px;
      font-weight: 700;
    }
    .pill.color {
      color: #fff;
    }
    .detail pre {
      max-height: 260px;
      overflow: auto;
      white-space: pre-wrap;
      border: 1px solid var(--line);
      border-radius: 8px;
      background: #fffdf8;
      padding: 12px;
      line-height: 1.55;
    }
    .detail ul,
    .list-panel ul {
      margin: 8px 0 0;
      padding-left: 18px;
      line-height: 1.6;
    }
    .task-link {
      width: 100%;
      min-height: 0;
      border: 0;
      background: transparent;
      color: var(--ink);
      cursor: pointer;
      display: block;
      padding: 3px 0;
      text-align: left;
    }
    .task-link:hover,
    .task-link:focus-visible {
      color: var(--accent);
      text-decoration: underline;
    }
    .below {
      display: grid;
      grid-template-columns: repeat(2, minmax(0, 1fr));
      gap: 18px;
      padding: 0 clamp(18px, 4vw, 44px) 44px;
    }
    .muted {
      color: var(--muted);
    }
    .status-list {
      padding: 0 clamp(18px, 4vw, 44px) 18px;
      color: var(--muted);
      font-size: 14px;
    }
    @media (max-width: 980px) {
      .stats {
        grid-template-columns: repeat(2, minmax(0, 1fr));
      }
      .layout,
      .below {
        grid-template-columns: 1fr;
      }
      #graph {
        height: 70vh;
        min-height: 500px;
      }
    }
  </style>
</head>
<body>
  <header>
    <h1>Linear Workplan DAG</h1>
    <p class="lede">Linear 업로드 전 <code>project_docs/linear/workplans/*.yaml</code>의 작업, 의존성, milestone 흐름을 빠르게 확인하는 로컬 HTML 뷰어입니다. 생성 시각: ${escapeHtml(model.generatedAt)}</p>
  </header>

  <section class="stats" aria-label="요약">
    ${statCard("파일 수", model.summary.fileCount)}
    ${statCard("작업 수", model.summary.taskCount)}
    ${statCard("dependency 수", model.summary.dependencyCount)}
    ${statCard("중복 local_id", model.summary.duplicateIds.length, model.summary.duplicateIds.length === 0)}
    ${statCard("누락 dependency", model.summary.missingDependencies.length, model.summary.missingDependencies.length === 0)}
    ${statCard("cycle", model.summary.cycle.length > 0 ? 1 : 0, model.summary.cycle.length === 0)}
  </section>

  <section class="status-list">
    <div>원본 파일: ${model.files.map((file) => `<code>${escapeHtml(file)}</code>`).join(", ")}</div>
    <div>중복 local_id: ${model.summary.duplicateIds.length === 0 ? "없음" : escapeHtml(model.summary.duplicateIds.join(", "))}</div>
    <div>누락 dependency: ${
      model.summary.missingDependencies.length === 0
        ? "없음"
        : escapeHtml(
            model.summary.missingDependencies
              .map((item) => `${item.task_id} -> ${item.missing_id}`)
              .join(", "),
          )
    }</div>
    <div>cycle: ${model.summary.cycle.length === 0 ? "없음" : escapeHtml(model.summary.cycle.join(" -> "))}</div>
  </section>

  <main class="layout">
    <section class="graph-panel">
      <div class="toolbar">
        <label for="milestoneFilter">milestone</label>
        <select id="milestoneFilter">
          <option value="">전체</option>
        </select>
        <span id="labelButtons" class="meta" aria-label="label 필터"></span>
        <button id="resetView" type="button">보기 재정렬</button>
      </div>
      <div id="graph" role="img" aria-label="Workplan dependency graph">${renderSvgGraph(model)}</div>
    </section>

    <aside class="side-panel">
      <div id="detail" class="detail">
        <h2>작업 상세</h2>
        <p class="muted">그래프에서 노드를 선택하면 원본 파일, 의존성, 완료 조건, 증거, 지표를 확인할 수 있습니다.</p>
      </div>
    </aside>
  </main>

  <section class="below">
    <section class="list-panel">
      <h2>시작 작업(no deps)</h2>
      <ul id="startingTasks"></ul>
    </section>
    <section class="list-panel">
      <h2>병목 작업</h2>
      <ul id="bottlenecks"></ul>
    </section>
  </section>

  <script id="workplan-data" type="application/json">${json}</script>
  <script>
    const model = JSON.parse(document.getElementById("workplan-data").textContent);
    const state = { milestone: "", label: "" };
    const taskById = new Map(model.tasks.map((task) => [task.local_id, task]));
    const milestoneSelect = document.getElementById("milestoneFilter");
    const labelButtons = document.getElementById("labelButtons");

    for (const milestone of model.milestones) {
      const option = document.createElement("option");
      option.value = milestone.id;
      option.textContent = milestone.title;
      milestoneSelect.appendChild(option);
    }

    labelButtons.appendChild(createLabelButton("전체", ""));
    for (const label of model.labels) {
      labelButtons.appendChild(createLabelButton(label, label));
    }

    const graph = document.getElementById("graph");
    const panState = {
      active: false,
      pointerId: null,
      startX: 0,
      startY: 0,
      startLeft: 0,
      startTop: 0,
      moved: false,
    };

    graph.addEventListener("click", (event) => {
      if (graph.dataset.dragged === "true") {
        return;
      }
      const node = closestGraphNode(event.target);
      if (!node) {
        return;
      }
      selectTask(node.getAttribute("data-id"), { center: false });
    });

    milestoneSelect.addEventListener("change", () => {
      state.milestone = milestoneSelect.value;
      applyFilters();
    });

    document.getElementById("resetView").addEventListener("click", () => {
      state.milestone = "";
      state.label = "";
      milestoneSelect.value = "";
      for (const item of labelButtons.querySelectorAll("button")) {
        item.classList.toggle("active", item.dataset.value === "");
      }
      applyFilters();
      graph.scrollTo({ left: 0, top: 0, behavior: "smooth" });
    });

    graph.addEventListener("pointerdown", (event) => {
      graph.dataset.dragged = "false";
      if (closestGraphNode(event.target)) {
        return;
      }
      panState.active = true;
      panState.pointerId = event.pointerId;
      panState.startX = event.clientX;
      panState.startY = event.clientY;
      panState.startLeft = graph.scrollLeft;
      panState.startTop = graph.scrollTop;
      panState.moved = false;
      graph.setPointerCapture?.(event.pointerId);
      graph.classList.add("is-panning");
    });

    graph.addEventListener("pointermove", (event) => {
      if (!panState.active || event.pointerId !== panState.pointerId) {
        return;
      }
      const deltaX = event.clientX - panState.startX;
      const deltaY = event.clientY - panState.startY;
      if (Math.abs(deltaX) + Math.abs(deltaY) > 4) {
        panState.moved = true;
        graph.dataset.dragged = "true";
      }
      graph.scrollLeft = panState.startLeft - deltaX;
      graph.scrollTop = panState.startTop - deltaY;
    });

    for (const eventName of ["pointerup", "pointercancel", "pointerleave"]) {
      graph.addEventListener(eventName, (event) => {
        if (!panState.active || event.pointerId !== panState.pointerId) {
          return;
        }
        panState.active = false;
        panState.pointerId = null;
        graph.releasePointerCapture?.(event.pointerId);
        graph.classList.remove("is-panning");
        if (panState.moved) {
          window.setTimeout(() => {
            graph.dataset.dragged = "false";
          }, 0);
        }
      });
    }

    renderList(
      "startingTasks",
      model.startingTasks,
      (task) => task.local_id + " - " + task.title + " (" + task.source_file + ")",
    );
    renderList(
      "bottlenecks",
      model.bottlenecks,
      (task) =>
        task.local_id +
        " - " +
        task.title +
        " (직접 " +
        task.unblocks_direct +
        ", 전체 " +
        task.unblocks_total +
        ")",
    );
    applyFilters();
    window.workplanGraph = {
      mode: "inline-svg",
      nodeCount: document.querySelectorAll(".graph-node").length,
      edgeCount: document.querySelectorAll(".graph-edge").length,
    };

    function createLabelButton(text, value) {
      const button = document.createElement("button");
      button.type = "button";
      button.textContent = text;
      button.dataset.value = value;
      button.addEventListener("click", () => {
        state.label = value;
        for (const item of labelButtons.querySelectorAll("button")) {
          item.classList.toggle("active", item.dataset.value === state.label);
        }
        applyFilters();
      });
      if (value === "") {
        button.classList.add("active");
      }
      return button;
    }

    function applyFilters() {
      const visibleNodes = new Set();

      for (const node of document.querySelectorAll(".graph-node")) {
        const labels = node.dataset.labels ? node.dataset.labels.split(",") : [];
        const milestoneMatches = !state.milestone || node.dataset.milestone === state.milestone;
        const labelMatches = !state.label || labels.includes(state.label);
        const visible = milestoneMatches && labelMatches;
        toggleSvgClass(node, "dimmed", !visible);
        if (visible) {
          visibleNodes.add(node.dataset.id);
        }
      }

      for (const edge of document.querySelectorAll(".graph-edge")) {
        const visible = visibleNodes.has(edge.dataset.source) && visibleNodes.has(edge.dataset.target);
        toggleSvgClass(edge, "dimmed", !visible);
      }
    }

    function addSvgClass(element, className) {
      const classes = new Set((element.getAttribute("class") || "").split(/\\s+/u).filter(Boolean));
      classes.add(className);
      element.setAttribute("class", [...classes].join(" "));
    }

    function removeSvgClass(element, className) {
      const classes = new Set((element.getAttribute("class") || "").split(/\\s+/u).filter(Boolean));
      classes.delete(className);
      element.setAttribute("class", [...classes].join(" "));
    }

    function toggleSvgClass(element, className, force) {
      if (force) {
        addSvgClass(element, className);
        return;
      }
      removeSvgClass(element, className);
    }

    function closestGraphNode(target) {
      let current = target;
      while (current && current !== graph) {
        if (current.getAttribute?.("class")?.split(/\\s+/u).includes("graph-node")) {
          return current;
        }
        current = current.parentNode;
      }
      return null;
    }

    function selectTask(taskId, options = {}) {
      const task = taskById.get(taskId);
      if (!task) {
        return;
      }
      document.querySelectorAll(".graph-node.selected").forEach((item) => {
        removeSvgClass(item, "selected");
      });
      const node = document.querySelector('.graph-node[data-id="' + cssEscape(taskId) + '"]');
      if (node) {
        addSvgClass(node, "selected");
        if (options.center) {
          centerNode(node);
        }
      }
      renderDetail(task);
    }

    function centerNode(node) {
      const circle = node.querySelector("circle");
      if (!circle) {
        return;
      }
      const x = Number(circle.getAttribute("cx"));
      const y = Number(circle.getAttribute("cy"));
      graph.scrollTo({
        left: Math.max(0, x - graph.clientWidth / 2),
        top: Math.max(0, y - graph.clientHeight / 2),
        behavior: "smooth",
      });
    }

    function cssEscape(value) {
      if (window.CSS?.escape) {
        return window.CSS.escape(value);
      }
      return String(value).replace(/["\\\\]/gu, "\\\\$&");
    }

    function renderDetail(task) {
      const detail = document.getElementById("detail");
      detail.replaceChildren();

      const title = document.createElement("h2");
      title.textContent = task.title;
      detail.appendChild(title);

      const id = document.createElement("p");
      id.className = "muted";
      id.textContent = task.local_id + " · " + task.source_file;
      detail.appendChild(id);

      const meta = document.createElement("div");
      meta.className = "meta";
      meta.appendChild(pill(task.milestone_title || task.milestone || "미지정", task.color));
      for (const label of task.labels) {
        meta.appendChild(pill(label));
      }
      detail.appendChild(meta);

      appendSection(detail, "description", task.description, "pre");
      appendSection(detail, "depends_on", task.depends_on);
      appendSection(detail, "done_when", task.done_when);
      appendSection(detail, "evidence", task.evidence);
      appendSection(detail, "metrics", task.metrics);
    }

    function appendSection(root, title, value, mode = "list") {
      const heading = document.createElement("h3");
      heading.textContent = title;
      root.appendChild(heading);

      if (mode === "pre") {
        const pre = document.createElement("pre");
        pre.textContent = value || "(없음)";
        root.appendChild(pre);
        return;
      }

      const list = document.createElement("ul");
      const items = Array.isArray(value) && value.length > 0 ? value : ["(없음)"];
      for (const item of items) {
        const li = document.createElement("li");
        li.textContent = item;
        list.appendChild(li);
      }
      root.appendChild(list);
    }

    function pill(text, color = "") {
      const span = document.createElement("span");
      span.className = "pill" + (color ? " color" : "");
      span.textContent = text;
      if (color) {
        span.style.background = color;
      }
      return span;
    }

    function renderList(id, items, format) {
      const root = document.getElementById(id);
      root.replaceChildren();
      for (const item of items) {
        const li = document.createElement("li");
        const button = document.createElement("button");
        button.type = "button";
        button.className = "task-link";
        button.textContent = format(item);
        button.addEventListener("click", () => {
          selectTask(item.local_id, { center: true });
        });
        li.appendChild(button);
        root.appendChild(li);
      }
    }
  </script>
</body>
</html>
`;
}

function renderSvgGraph(model) {
  const layout = layoutGraph(model);
  const edgeMarkup = model.edges
    .map((edge) => {
      const source = layout.positions.get(edge.source);
      const target = layout.positions.get(edge.target);
      if (!source || !target) {
        return "";
      }
      const startX = source.x + 24;
      const startY = source.y;
      const endX = target.x - 24;
      const endY = target.y;
      const midX = startX + Math.max(40, (endX - startX) / 2);
      const pathData = `M ${startX} ${startY} C ${midX} ${startY}, ${midX} ${endY}, ${endX} ${endY}`;
      return `<path class="graph-edge" data-source="${escapeHtml(edge.source)}" data-target="${escapeHtml(edge.target)}" d="${pathData}" marker-end="url(#arrow)"></path>`;
    })
    .join("\n");

  const nodeMarkup = model.tasks
    .map((task) => {
      const position = layout.positions.get(task.local_id);
      const labelLines = wrapSvgLabel(task.title, 22, 2);
      const labels = task.labels.join(",");
      const titleLines = labelLines
        .map(
          (line, index) =>
            `<tspan x="${position.x}" y="${position.y + 38 + index * 14}">${escapeHtml(line)}</tspan>`,
        )
        .join("");
      return `<g class="graph-node" tabindex="0" data-id="${escapeHtml(task.local_id)}" data-milestone="${escapeHtml(task.milestone)}" data-labels="${escapeHtml(labels)}">
  <title>${escapeHtml(task.local_id)} - ${escapeHtml(task.title)}</title>
  <circle cx="${position.x}" cy="${position.y}" r="22" fill="${escapeHtml(task.color)}"></circle>
  <text class="node-id" text-anchor="middle" x="${position.x}" y="${position.y + 4}">${escapeHtml(shortId(task.local_id))}</text>
  <text text-anchor="middle">${titleLines}</text>
</g>`;
    })
    .join("\n");

  return `<svg viewBox="0 0 ${layout.width} ${layout.height}" width="${layout.width}" height="${layout.height}" aria-label="Workplan DAG">
  <defs>
    <marker id="arrow" viewBox="0 0 10 10" refX="8" refY="5" markerWidth="7" markerHeight="7" orient="auto-start-reverse">
      <path d="M 0 0 L 10 5 L 0 10 z" fill="#8a7d6b"></path>
    </marker>
  </defs>
  <g class="edges">${edgeMarkup}</g>
  <g class="nodes">${nodeMarkup}</g>
</svg>`;
}

function layoutGraph(model) {
  const taskById = new Map(model.tasks.map((task) => [task.local_id, task]));
  const depthCache = new Map();

  function depthOf(id, stack = new Set()) {
    if (depthCache.has(id)) {
      return depthCache.get(id);
    }
    if (stack.has(id) || !taskById.has(id)) {
      return 0;
    }
    stack.add(id);
    const dependencies = taskById.get(id).depends_on.filter((dependency) => taskById.has(dependency));
    const depth = dependencies.length === 0 ? 0 : Math.max(...dependencies.map((dep) => depthOf(dep, stack))) + 1;
    stack.delete(id);
    depthCache.set(id, depth);
    return depth;
  }

  const columns = new Map();
  for (const task of model.tasks) {
    const depth = depthOf(task.local_id);
    if (!columns.has(depth)) {
      columns.set(depth, []);
    }
    columns.get(depth).push(task);
  }

  const columnWidth = 250;
  const rowHeight = 96;
  const marginX = 88;
  const marginY = 66;
  const sortedColumns = [...columns.keys()].sort((left, right) => left - right);
  const widestColumn = Math.max(...[...columns.values()].map((tasks) => tasks.length), 1);
  const width = Math.max(980, marginX * 2 + (sortedColumns.length - 1) * columnWidth + 220);
  const height = Math.max(520, marginY * 2 + widestColumn * rowHeight);
  const positions = new Map();

  for (const depth of sortedColumns) {
    const tasks = columns
      .get(depth)
      .sort((left, right) => left.milestone.localeCompare(right.milestone) || left.local_id.localeCompare(right.local_id));
    const columnHeight = (tasks.length - 1) * rowHeight;
    const startY = Math.max(marginY, (height - columnHeight) / 2);

    tasks.forEach((task, rowIndex) => {
      positions.set(task.local_id, {
        x: marginX + depth * columnWidth,
        y: startY + rowIndex * rowHeight,
      });
    });
  }

  return { width, height, positions };
}

function wrapSvgLabel(value, maxChars, maxLines) {
  const words = String(value).split(/\s+/u);
  const lines = [];
  let current = "";

  for (const word of words) {
    const candidate = current === "" ? word : `${current} ${word}`;
    if (candidate.length <= maxChars) {
      current = candidate;
      continue;
    }
    if (current !== "") {
      lines.push(current);
    }
    current = word;
    if (lines.length === maxLines - 1) {
      break;
    }
  }

  if (current !== "" && lines.length < maxLines) {
    lines.push(current);
  }

  if (lines.length === 0) {
    lines.push(String(value).slice(0, maxChars));
  }

  const lastIndex = lines.length - 1;
  if (String(value).length > lines.join(" ").length) {
    lines[lastIndex] = `${lines[lastIndex].slice(0, Math.max(0, maxChars - 1))}...`;
  }
  return lines;
}

function shortId(value) {
  const parts = String(value).split(".");
  return parts.at(-1).slice(0, 10);
}

function statCard(label, value, ok = null) {
  const stateClass = ok === null ? "" : ok ? " ok" : " warn";
  return `<article class="stat${stateClass}"><span>${escapeHtml(label)}</span><strong>${escapeHtml(String(value))}</strong></article>`;
}

function escapeHtml(value) {
  return String(value)
    .replace(/&/gu, "&amp;")
    .replace(/</gu, "&lt;")
    .replace(/>/gu, "&gt;")
    .replace(/"/gu, "&quot;")
    .replace(/'/gu, "&#39;");
}

main().catch((error) => {
  console.error(error.message);
  process.exitCode = 1;
});
