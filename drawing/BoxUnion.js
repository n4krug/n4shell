.pragma library

"use strict";

// BoxUnion.js
//
// Line-sweep union of axis-aligned rectangles, producing rectilinear polygon
// contours suitable for rendering as QtQuick.Shapes paths.
//
// API:
//   unionRectangles(rects)      -> [ { points: [[x,y],...], isHole: bool }, ... ]
//   rectsFromItems(items, target) -> [ {x,y,w,h}, ... ]   (input shaping helper)
//   roundedSvgPath(points, radius, min, max) -> SVG path string
//
// `rects` is an array of { x, y, w, h } with w,h >= 0.
// Returned contours are closed implicitly (last vertex connects to first);
// outer contours are CCW (signed area > 0), holes are CW (signed area < 0).
// Degenerate (zero-area) rectangles are ignored.
//
// Algorithm: coordinate-compress all rect edges onto a grid, mark covered
// cells, emit directed boundary edges with the covered region on the left,
// then chain edges into closed contours. At ambiguous "saddle" vertices
// (two diagonal cells filled, touching only at a corner) the left-turn rule
// is preferred, which treats the diagonal filled cells as separate loops.

function unionRectangles(rects) {
    rects = (rects || []).filter(r => r && r.w > 0 && r.h > 0);
    const n = rects.length;
    if (n === 0) return [];

    // --- coordinate compression ------------------------------------------
    // Everything below works in grid INDEX space (i, j) rather than in
    // floating point coordinates. Integer keys mean flat typed arrays and
    // head/next linked lists instead of Sets, Maps and "x,y" string keys,
    // which is where nearly all of the cost used to go.
    const xs = new Array(n * 2);
    const ys = new Array(n * 2);
    for (let k = 0; k < n; k++) {
        const r = rects[k];
        xs[k * 2] = r.x; xs[k * 2 + 1] = r.x + r.w;
        ys[k * 2] = r.y; ys[k * 2 + 1] = r.y + r.h;
    }
    _sortedUnique(xs);
    _sortedUnique(ys);

    const nx = xs.length;
    const ny = ys.length;
    if (nx < 2 || ny < 2) return [];

    const cw = nx - 1; // cells per row
    const ch = ny - 1; // cells per column

    // cover[j * cw + i] = cell [xs[i],xs[i+1]) x [ys[j],ys[j+1]) is covered
    const cover = new Uint8Array(cw * ch);
    for (let k = 0; k < n; k++) {
        const r = rects[k];
        const i0 = _lowerBound(xs, r.x), i1 = _lowerBound(xs, r.x + r.w);
        const j0 = _lowerBound(ys, r.y), j1 = _lowerBound(ys, r.y + r.h);
        for (let j = j0; j < j1; j++) {
            const row = j * cw;
            for (let i = i0; i < i1; i++) cover[row + i] = 1;
        }
    }

    const edges = _collectBoundaryEdges(cover, nx, ny, cw, ch);
    const contours = _chainContours(edges, nx, xs, ys);
    return contours
        .map(pts => _dropCollinear(pts))
        .filter(pts => pts.length >= 3)
        .map(pts => ({ points: pts, isHole: _signedArea(pts) < 0 }));
}

// Sorts numerically and removes duplicates in place.
function _sortedUnique(arr) {
    arr.sort(_numAsc);
    let m = 0;
    for (let i = 0; i < arr.length; i++) {
        if (i === 0 || arr[i] !== arr[i - 1]) arr[m++] = arr[i];
    }
    arr.length = m;
    return arr;
}

function _numAsc(a, b) {
    return a - b;
}

// First index whose value is >= v. Callers only look up values that are
// guaranteed to be present, so this returns the exact index of v.
function _lowerBound(arr, v) {
    let lo = 0, hi = arr.length - 1;
    while (lo < hi) {
        const mid = (lo + hi) >> 1;
        if (arr[mid] < v) lo = mid + 1;
        else hi = mid;
    }
    return lo;
}

// Removes vertices that lie on the straight segment between their neighbors
// (including the wrap-around across the implicit closing edge), so contours
// contain only true corners. Closed polygon is treated as cyclic.
function _dropCollinear(pts) {
    const n = pts.length;
    if (n < 3) return pts.slice();
    const out = [];
    for (let i = 0; i < n; i++) {
        const a = pts[(i - 1 + n) % n];
        const b = pts[i];
        const c = pts[(i + 1) % n];
        const cross = (b[0] - a[0]) * (c[1] - b[1]) - (b[1] - a[1]) * (c[0] - b[0]);
        if (cross !== 0) out.push(b);
    }
    return out;
}

// --- internal helpers -----------------------------------------------------

// Each edge is a flat (i0, j0, i1, j1) quadruple in grid index space, with the
// covered region on its left. Returns { e: Int32Array, m: edge count }.
function _collectBoundaryEdges(cover, nx, ny, cw, ch) {
    const e = new Int32Array((ny * cw + nx * ch) * 4);
    let m = 0;

    // Horizontal edges along y = ys[j], spanning cell column i.
    for (let j = 0; j < ny; j++) {
        const rowAbove = j * cw;       // valid when j < ch
        const rowBelow = (j - 1) * cw; // valid when j > 0
        for (let i = 0; i < cw; i++) {
            const above = (j < ch) ? cover[rowAbove + i] : 0;
            const below = (j > 0) ? cover[rowBelow + i] : 0;
            if (above === below) continue;
            const o = m * 4;
            if (above) { e[o] = i; e[o + 1] = j; e[o + 2] = i + 1; e[o + 3] = j; } // +x
            else       { e[o] = i + 1; e[o + 1] = j; e[o + 2] = i; e[o + 3] = j; } // -x
            m++;
        }
    }

    // Vertical edges along x = xs[i], spanning cell row j.
    for (let i = 0; i < nx; i++) {
        for (let j = 0; j < ch; j++) {
            const row = j * cw;
            const left = (i > 0) ? cover[row + i - 1] : 0;
            const right = (i < cw) ? cover[row + i] : 0;
            if (left === right) continue;
            const o = m * 4;
            if (left) { e[o] = i; e[o + 1] = j; e[o + 2] = i; e[o + 3] = j + 1; } // +y
            else      { e[o] = i; e[o + 1] = j + 1; e[o + 2] = i; e[o + 3] = j; } // -y
            m++;
        }
    }

    return { e: e, m: m };
}

function _chainContours(edges, nx, xs, ys) {
    const e = edges.e;
    const m = edges.m;
    if (m === 0) return [];

    // Adjacency indexed by the integer vertex key k = j * nx + i, stored as a
    // head/next linked list. Edges are prepended in descending order so each
    // list ends up in ascending edge order, matching the previous behaviour.
    const head = new Int32Array(nx * ys.length).fill(-1);
    const next = new Int32Array(m).fill(-1);
    for (let c = m - 1; c >= 0; c--) {
        const k = e[c * 4 + 1] * nx + e[c * 4];
        next[c] = head[k];
        head[k] = c;
    }

    const used = new Uint8Array(m);
    const contours = [];

    for (let start = 0; start < m; start++) {
        if (used[start]) continue;
        const pts = [];
        const startK = e[start * 4 + 1] * nx + e[start * 4];
        let cur = start;
        let guard = 0;
        while (guard++ < m + 2) {
            used[cur] = 1;
            const o = cur * 4;
            pts.push([xs[e[o]], ys[e[o + 1]]]);
            const endK = e[o + 3] * nx + e[o + 2];
            if (endK === startK) break;

            const di = _dirIndex(e[o + 2] - e[o], e[o + 3] - e[o + 1]);
            let best = -1;
            let bestRank = Number.POSITIVE_INFINITY;
            for (let c = head[endK]; c !== -1; c = next[c]) {
                if (used[c]) continue;
                const co = c * 4;
                const ci = _dirIndex(e[co + 2] - e[co], e[co + 3] - e[co + 1]);
                const rank = _turnRank((ci - di + 4) % 4);
                if (rank < bestRank) { bestRank = rank; best = c; }
            }
            if (best === -1) break;
            cur = best;
        }
        if (pts.length >= 3) contours.push(pts);
    }
    return contours;
}

// 0 = +x, 1 = +y, 2 = -x, 3 = -y (counterclockwise order)
function _dirIndex(dx, dy) {
    if (dx > 0) return 0;
    if (dx < 0) return 2;
    if (dy > 0) return 1;
    return 3;
}

// Prefer left turn (CCW 90), then right turn (CW 90), then U-turn last.
// A 0 (straight) should never occur at a rectilinear vertex terminator.
function _turnRank(ccwAmount) {
    if (ccwAmount === 1) return 0; // left
    if (ccwAmount === 3) return 1; // right
    return 2;                       // U-turn (2)
}

function _signedArea(pts) {
    let s = 0;
    for (let i = 0; i < pts.length; i++) {
        const a = pts[i];
        const b = pts[(i + 1) % pts.length];
        s += a[0] * b[1] - b[0] * a[1];
    }
    return s / 2;
}

// Cheap identity of the union input, used to skip recomputation when nothing
// actually moved. Quantised to 2 decimals so sub-pixel float noise (and the
// identical repeat signals that come with it) does not invalidate the cache.
function _q(v) {
    return Math.round(v * 100) / 100;
}

function rectsSignature(rects, w, h) {
    let s = _q(w) + "x" + _q(h);
    for (let i = 0; i < rects.length; i++) {
        const r = rects[i];
        s += "|" + _q(r.x) + "," + _q(r.y) + "," + _q(r.w) + "," + _q(r.h);
    }
    return s;
}

// --- input shaping --------------------------------------------------------

// Maps a list of registered items to {x,y,w,h} rects in `target`'s coordinate
// space by calling each item's rectIn(target). Items lacking rectIn are
// skipped. Pure convenience; unionRectangles is the only thing that needs the
// rects, so callers may build rects any other way instead.
function rectsFromItems(items, target) {
    const out = [];
    for (const item of items || []) {
        if (!item || typeof item.rectIn !== "function") continue;
        const r = item.rectIn(target);
        if (!r) continue;
        out.push({ x: r.x, y: r.y, w: r.w, h: r.h });
    }
    return out;
}

// Emits the rounded outline of one contour directly as an SVG path string.
//
// Fusing the corner rounding and the serialisation into a single pass avoids
// building an intermediate array (one allocation per vertex) plus the six
// scratch objects per vertex that the previous roundPath() created.
function roundedSvgPath(pathCoords, radius, min, max) {
    const n = pathCoords.length;
    if (n === 0) return "";

    let body = "";
    let startX = 0;
    let startY = 0;

    for (let i = 0; i < n; i++) {
        // Corner is pathCoords[(i + 1) % n]; c1 and c3 are its neighbours.
        const c1Raw = pathCoords[i];
        const c2Raw = pathCoords[(i + 1) % n];
        const c3Raw = pathCoords[(i + 2) % n];

        const c2x = c2Raw[0], c2y = c2Raw[1];

        // Vectors from the corner towards each neighbour.
        const v1x = c1Raw[0] - c2x, v1y = c1Raw[1] - c2y;
        const v3x = c3Raw[0] - c2x, v3y = c3Raw[1] - c2y;

        const angle = Math.abs(Math.atan2(
            v1x * v3y - v1y * v3x,
            v1x * v3x + v1y * v3y
        ));

        // Halved so the neighbouring corners can round by as much as this one.
        const d1 = Math.hypot(v1x, v1y) / 2;
        const d3 = Math.hypot(v3x, v3y) / 2;

        const r = Math.min(radius, d1, d3);

        // Ideal control point distance for a circular arc approximation.
        const ideal = (4 / 3) * Math.tan(
            Math.PI / (2 * ((2 * Math.PI) / angle))
        ) * r * (angle < Math.PI / 2 ? 1 + Math.cos(angle) : 1);

        const s1x = c2x + v1x * r / d1 / 2, s1y = c2y + v1y * r / d1 / 2;
        const p1x = c2x + v1x * (r - ideal) / d1 / 2, p1y = c2y + v1y * (r - ideal) / d1 / 2;
        const e3x = c2x + v3x * r / d3 / 2, e3y = c2y + v3y * r / d3 / 2;
        const p2x = c2x + v3x * (r - ideal) / d3 / 2, p2y = c2y + v3y * (r - ideal) / d3 / 2;

        // At the last vertex the end of the curve is the polygon's start point.
        if (i === n - 1) { startX = e3x; startY = e3y; }

        // Corners sitting on the canvas edge are not rounded.
        if (c2x >= max.x || c2x <= min.x || c2y >= max.y || c2y <= min.y) {
            body += "L " + _q(c2x) + " " + _q(c2y) + " ";
            continue;
        }

        body += "L " + _q(s1x) + " " + _q(s1y) + " C "
              + _q(p1x) + " " + _q(p1y) + " "
              + _q(p2x) + " " + _q(p2y) + " "
              + _q(e3x) + " " + _q(e3y) + " ";
    }

    return "M " + _q(startX) + " " + _q(startY) + " " + body + "Z";
}